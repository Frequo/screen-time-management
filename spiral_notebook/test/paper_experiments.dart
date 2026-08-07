// Monte Carlo simulations backing Section 4 of the research paper.
//
// Both experiments drive the real SpiralAppState pull path (pullCharacters ->
// _performPull -> _rollRarity) rather than reimplementing the probability
// logic, so the reported figures describe the shipped code.
//
// Not named *_test.dart so it stays out of the normal `flutter test` sweep.
// Run explicitly:  flutter test test/paper_experiments.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spiral_notebook/app_state.dart';

const int kTrials = 100000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Experiment A: base rarity distribution (pity suppressed)', () {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    final Map<CharacterRarity, int> counts = <CharacterRarity, int>{
      for (final CharacterRarity r in CharacterRarity.values) r: 0,
    };

    for (int i = 0; i < kTrials; i += 1) {
      // Resetting pity before every pull keeps pityCounter at 1 after the
      // in-method increment, so `pityCounter >= pityLimit` is never true and
      // _rollRarity returns the unmodified base distribution.
      appState.pityCounter = 0;
      appState.bits = SpiralAppState.pullCost;
      final List<GameCharacter>? pulled = appState.pullCharacters(1);
      counts[pulled!.single.rarity] = counts[pulled.single.rarity]! + 1;
    }

    const Map<CharacterRarity, double> targets = <CharacterRarity, double>{
      CharacterRarity.common: 68.0,
      CharacterRarity.rare: 22.0,
      CharacterRarity.epic: 9.0,
      CharacterRarity.legendary: 1.0,
    };

    // ignore: avoid_print
    print('\n=== EXPERIMENT A: rarity distribution ($kTrials rolls) ===');
    // ignore: avoid_print
    print('tier,target_pct,observed_pct,observed_count,abs_deviation');
    double deviationSum = 0;
    for (final CharacterRarity r in <CharacterRarity>[
      CharacterRarity.common,
      CharacterRarity.rare,
      CharacterRarity.epic,
      CharacterRarity.legendary,
    ]) {
      final int n = counts[r]!;
      final double pct = n * 100 / kTrials;
      final double dev = (pct - targets[r]!).abs();
      deviationSum += dev;
      // ignore: avoid_print
      print(
        '${r.label},${targets[r]!.toStringAsFixed(1)},'
        '${pct.toStringAsFixed(3)},$n,${dev.toStringAsFixed(3)}',
      );
    }
    // ignore: avoid_print
    print(
      'mean_absolute_deviation_pct,${(deviationSum / 4).toStringAsFixed(4)}',
    );
  });

  test('Experiment B: pulls required to obtain a Legendary', () async {
    final SpiralAppState appState = SpiralAppState();
    addTearDown(appState.dispose);

    final List<int> pullsToLegendary = <int>[];

    for (int run = 0; run < kTrials; run += 1) {
      appState.pityCounter = 0;
      int pulls = 0;
      while (true) {
        appState.bits = SpiralAppState.pullCost;
        final List<GameCharacter>? pulled = appState.pullCharacters(1);
        pulls += 1;
        if (pulled!.single.rarity == CharacterRarity.legendary) {
          break;
        }
      }
      pullsToLegendary.add(pulls);

      // pullCharacters fires _persistProgress() without awaiting it. Over
      // millions of pulls those pending futures would otherwise accumulate
      // without bound, so yield periodically to let the queue drain.
      if (run % 500 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    pullsToLegendary.sort();
    final int n = pullsToLegendary.length;
    final double mean =
        pullsToLegendary.reduce((int a, int b) => a + b) / n;
    final int median = n.isOdd
        ? pullsToLegendary[n ~/ 2]
        : ((pullsToLegendary[n ~/ 2 - 1] + pullsToLegendary[n ~/ 2]) / 2)
              .round();
    final int atCap =
        pullsToLegendary.where((int p) => p == SpiralAppState.pityLimit).length;

    // ignore: avoid_print
    print('\n=== EXPERIMENT B: pulls to Legendary ($kTrials runs) ===');
    // ignore: avoid_print
    print('mean,${mean.toStringAsFixed(2)}');
    // ignore: avoid_print
    print('median,$median');
    // ignore: avoid_print
    print('min,${pullsToLegendary.first}');
    // ignore: avoid_print
    print('max,${pullsToLegendary.last}');
    // ignore: avoid_print
    print(
      'runs_at_pity_cap,$atCap,${(atCap * 100 / n).toStringAsFixed(2)}%',
    );

    // Histogram buckets for the paper's figure.
    // ignore: avoid_print
    print('bucket,count');
    for (int lo = 1; lo <= 100; lo += 10) {
      final int hi = lo + 9;
      final int c = pullsToLegendary
          .where((int p) => p >= lo && p <= hi)
          .length;
      // ignore: avoid_print
      print('$lo-$hi,$c');
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
