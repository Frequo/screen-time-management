// Server-side gacha rules. Kept free of Firebase imports so the odds can be
// unit-tested directly. These constants are the source of truth for the live
// game; SpiralAppState mirrors them only for display and the offline build.
import { randomInt } from 'node:crypto';

export const PULL_COST = 100;
export const PITY_LIMIT = 100;
export const MAX_PULLS_PER_CALL = 10;

// Chance of drawing from characters the player doesn't own yet, when the
// rolled rarity still has some.
export const MISSING_CHARACTER_BIAS = 0.7;

export const RARITY_WEIGHTS = Object.freeze({
  common: 680,
  rare: 220,
  epic: 90,
  legendary: 10,
});

const RARITIES = Object.keys(RARITY_WEIGHTS);

// Uniform float in [0, 1) from the CSPRNG, matching Random.nextDouble().
// randomInt's range must be under 2^48, so 2^32 steps of resolution.
function cryptoRandom() {
  return randomInt(2 ** 32) / 2 ** 32;
}

export const defaultRng = Object.freeze({
  nextInt: (max) => randomInt(max),
  nextDouble: cryptoRandom,
});

/** Visible, pullable characters from a `catalog/characters` document. */
export function gachaPoolFromCatalog(data) {
  if (data?.schemaVersion !== 1 || !Array.isArray(data.characters)) {
    throw new Error('Unsupported character catalog document');
  }
  return data.characters.filter(
    (character) =>
      typeof character?.id === 'string' &&
      character.id.trim() !== '' &&
      RARITIES.includes(character.rarity) &&
      character.pullable === true &&
      character.hidden !== true,
  );
}

/**
 * Applies [count] pulls to the player's progress and returns the new state.
 * Returns null without changing anything when the pool is empty or the player
 * can't afford the pulls. [progress] is not mutated.
 */
export function performPulls({ progress, pool, count, tutorial = false, rng = defaultRng }) {
  if (!Number.isInteger(count) || count <= 0 || pool.length === 0) {
    return null;
  }

  let bits = nonNegativeInt(progress.bits);
  let totalPulls = nonNegativeInt(progress.totalPulls);
  let pityCounter = nonNegativeInt(progress.pityCounter);
  const collection = sanitizedCollection(progress.collection);
  let tutorialPullClaimed = progress.tutorialPullClaimed === true;

  // The tutorial's first draw is free: top the balance up to one pull. Only
  // granted once per account so restarting the tutorial can't farm it.
  if (tutorial && count === 1 && !tutorialPullClaimed && progress.hasCompletedTutorial !== true) {
    bits = Math.max(bits, PULL_COST);
    tutorialPullClaimed = true;
  }

  if (bits < PULL_COST * count) {
    return null;
  }

  const availableWeights = RARITIES
    .filter((rarity) => pool.some((character) => character.rarity === rarity))
    .map((rarity) => [rarity, RARITY_WEIGHTS[rarity]]);
  const hasPullableLegendary = availableWeights.some(([rarity]) => rarity === 'legendary');

  const results = [];
  for (let index = 0; index < count; index += 1) {
    bits -= PULL_COST;
    totalPulls += 1;
    pityCounter += 1;

    const guaranteedLegendary = pityCounter >= PITY_LIMIT && hasPullableLegendary;
    const rarity = guaranteedLegendary ? 'legendary' : rollRarity(availableWeights, rng);
    const rarityPool = pool.filter((character) => character.rarity === rarity);
    const missingFromPool = rarityPool.filter((character) => !(collection[character.id] > 0));
    const candidates =
      missingFromPool.length > 0 && rng.nextDouble() < MISSING_CHARACTER_BIAS
        ? missingFromPool
        : rarityPool;
    const pulled = candidates[rng.nextInt(candidates.length)];

    collection[pulled.id] = (collection[pulled.id] ?? 0) + 1;
    if (pulled.rarity === 'legendary' || guaranteedLegendary) {
      pityCounter = 0;
    }
    results.push(pulled.id);
  }

  return {
    results,
    progress: {
      bits,
      totalPulls,
      pityCounter,
      collection,
      lastPulledCharacterId: results[results.length - 1],
      tutorialPullClaimed,
    },
  };
}

function rollRarity(weights, rng) {
  const total = weights.reduce((sum, [, weight]) => sum + weight, 0);
  let roll = rng.nextInt(total);
  for (const [rarity, weight] of weights) {
    if (roll < weight) {
      return rarity;
    }
    roll -= weight;
  }
  throw new Error('No pullable character rarity available');
}

function nonNegativeInt(value) {
  return Number.isInteger(value) && value > 0 ? value : 0;
}

function sanitizedCollection(value) {
  const collection = {};
  if (value && typeof value === 'object') {
    for (const [id, copies] of Object.entries(value)) {
      if (Number.isInteger(copies) && copies > 0) {
        collection[id] = copies;
      }
    }
  }
  return collection;
}
