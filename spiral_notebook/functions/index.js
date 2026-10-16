import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import * as functionsV1 from 'firebase-functions/v1';

import { MAX_PULLS_PER_CALL, gachaPoolFromCatalog, performPulls } from './gacha.js';

initializeApp();
const db = getFirestore();

/**
 * Spends bits on [count] gacha pulls for the signed-in player.
 *
 * Request:  { count: 1..10, tutorial?: boolean }
 * Response: { characterIds, bits, totalPulls, pityCounter, collection,
 *             lastPulledCharacterId }
 *
 * Fails with `failed-precondition` when the player can't afford the pulls or
 * nothing is pullable, so the app can tell that apart from a network error.
 */
export const pullCharacters = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in to pull characters.');
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError('permission-denied', 'Verify your email before pulling.');
  }

  const count = request.data?.count;
  const tutorial = request.data?.tutorial === true;
  if (!Number.isInteger(count) || count < 1 || count > MAX_PULLS_PER_CALL) {
    throw new HttpsError('invalid-argument', `count must be 1-${MAX_PULLS_PER_CALL}.`);
  }

  const userRef = db.collection('users').doc(uid);
  const catalogRef = db.doc('catalog/characters');

  return db.runTransaction(async (transaction) => {
    const [userSnapshot, catalogSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(catalogRef),
    ]);

    let pool;
    try {
      pool = gachaPoolFromCatalog(catalogSnapshot.data());
    } catch (error) {
      logger.error('Character catalog is unusable', error);
      throw new HttpsError('internal', 'The character catalog is unavailable.');
    }

    const outcome = performPulls({
      progress: userSnapshot.data() ?? {},
      pool,
      count,
      tutorial,
    });
    if (outcome == null) {
      throw new HttpsError(
        'failed-precondition',
        pool.length === 0 ? 'No characters are pullable right now.' : 'Not enough bits.',
      );
    }

    transaction.set(
      userRef,
      { ...outcome.progress, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );

    const { bits, totalPulls, pityCounter, collection, lastPulledCharacterId } = outcome.progress;
    return {
      characterIds: outcome.results,
      bits,
      totalPulls,
      pityCounter,
      collection,
      lastPulledCharacterId,
    };
  });
});

// Removes a player's progress once their auth account is gone. The client can
// no longer restore pull-owned fields (collection, pity) itself, so it deletes
// only the auth user and leaves the Firestore cleanup to this trigger. That
// way a failed deletion (e.g. requires-recent-login) can't wipe progress.
export const deleteUserData = functionsV1.auth.user().onDelete(async (user) => {
  await db.collection('users').doc(user.uid).delete();
});
