import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  PITY_LIMIT,
  PULL_COST,
  gachaPoolFromCatalog,
  performPulls,
} from './gacha.js';

const character = (id, rarity, extra = {}) => ({
  id,
  rarity,
  pullable: true,
  hidden: false,
  ...extra,
});

const fullPool = [
  character('c1', 'common'),
  character('c2', 'common'),
  character('r1', 'rare'),
  character('e1', 'epic'),
  character('l1', 'legendary'),
];

test('catalog pool keeps only visible, pullable characters', () => {
  const pool = gachaPoolFromCatalog({
    schemaVersion: 1,
    characters: [
      character('active', 'common'),
      character('display-only', 'rare', { pullable: false }),
      character('hidden', 'legendary', { hidden: true }),
      character('bad-rarity', 'mythic'),
    ],
  });
  assert.deepEqual(pool.map((c) => c.id), ['active']);
  assert.throws(() => gachaPoolFromCatalog({ schemaVersion: 2, characters: [] }));
  assert.throws(() => gachaPoolFromCatalog(undefined));
});

test('a pull spends bits and records the character', () => {
  const progress = { bits: PULL_COST * 3, totalPulls: 4, pityCounter: 2, collection: {} };
  const outcome = performPulls({ progress, pool: fullPool, count: 2 });
  assert.equal(outcome.results.length, 2);
  assert.equal(outcome.progress.bits, PULL_COST);
  assert.equal(outcome.progress.totalPulls, 6);
  assert.equal(outcome.progress.lastPulledCharacterId, outcome.results[1]);
  const copies = Object.values(outcome.progress.collection).reduce((a, b) => a + b, 0);
  assert.equal(copies, 2);
  // Input is not mutated.
  assert.deepEqual(progress.collection, {});
  assert.equal(progress.bits, PULL_COST * 3);
});

test('insufficient bits or an empty pool changes nothing', () => {
  assert.equal(performPulls({ progress: { bits: PULL_COST * 9 }, pool: fullPool, count: 10 }), null);
  assert.equal(performPulls({ progress: { bits: PULL_COST * 10 }, pool: [], count: 1 }), null);
  assert.equal(performPulls({ progress: { bits: PULL_COST }, pool: fullPool, count: 0 }), null);
});

test('malformed stored values are treated as zero, not trusted', () => {
  const outcome = performPulls({
    progress: { bits: '99999', pityCounter: -5, collection: { c1: 'lots', c2: 2.5 } },
    pool: fullPool,
    count: 1,
  });
  assert.equal(outcome, null);
});

test('reaching the pity limit guarantees a legendary and resets pity', () => {
  const outcome = performPulls({
    progress: { bits: PULL_COST, pityCounter: PITY_LIMIT - 1 },
    pool: fullPool,
    count: 1,
  });
  assert.deepEqual(outcome.results, ['l1']);
  assert.equal(outcome.progress.pityCounter, 0);
});

test('pity keeps accruing when no legendary is pullable', () => {
  const outcome = performPulls({
    progress: { bits: PULL_COST * 10, pityCounter: PITY_LIMIT - 1 },
    pool: [character('axel', 'common')],
    count: 10,
  });
  assert.ok(outcome.results.every((id) => id === 'axel'));
  assert.equal(outcome.progress.pityCounter, PITY_LIMIT + 9);
});

test('the tutorial draw is free once, then costs bits like any pull', () => {
  const first = performPulls({ progress: { bits: 0 }, pool: fullPool, count: 1, tutorial: true });
  assert.equal(first.progress.bits, 0);
  assert.equal(first.progress.tutorialPullClaimed, true);

  const again = performPulls({ progress: first.progress, pool: fullPool, count: 1, tutorial: true });
  assert.equal(again, null);

  const completed = performPulls({
    progress: { bits: 0, hasCompletedTutorial: true },
    pool: fullPool,
    count: 1,
    tutorial: true,
  });
  assert.equal(completed, null);

  const multi = performPulls({ progress: { bits: 0 }, pool: fullPool, count: 10, tutorial: true });
  assert.equal(multi, null);
});

test('base rarity odds match 68 / 22 / 9 / 1', () => {
  const trials = 200_000;
  const rarityById = Object.fromEntries(fullPool.map((c) => [c.id, c.rarity]));
  const counts = { common: 0, rare: 0, epic: 0, legendary: 0 };
  for (let i = 0; i < trials; i += 1) {
    const { results } = performPulls({ progress: { bits: PULL_COST }, pool: fullPool, count: 1 });
    counts[rarityById[results[0]]] += 1;
  }
  const expected = { common: 0.68, rare: 0.22, epic: 0.09, legendary: 0.01 };
  for (const [rarity, p] of Object.entries(expected)) {
    // Five standard deviations: effectively never flaky.
    const tolerance = 5 * Math.sqrt((p * (1 - p)) / trials);
    assert.ok(
      Math.abs(counts[rarity] / trials - p) < tolerance,
      `${rarity}: ${counts[rarity] / trials} vs ${p}`,
    );
  }
});

test('unowned characters of the rolled rarity are favoured 70%', () => {
  const pool = [character('owned', 'common'), character('missing', 'common')];
  const trials = 50_000;
  let missing = 0;
  for (let i = 0; i < trials; i += 1) {
    const { results } = performPulls({
      progress: { bits: PULL_COST, collection: { owned: 1 } },
      pool,
      count: 1,
    });
    if (results[0] === 'missing') missing += 1;
  }
  // 0.7 from the bias + 0.3 * 0.5 from the uniform fallback.
  assert.ok(Math.abs(missing / trials - 0.85) < 0.01, `${missing / trials}`);
});
