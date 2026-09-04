import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/services/character_catalog.dart';
import 'package:spiral_notebook/screens/characterview.dart';
import 'package:spiral_notebook/widgets/character_image.dart';

import 'support/character_roster.dart';

GameCharacter character(
  String id,
  CharacterRarity rarity, {
  bool pullable = true,
  bool hidden = false,
}) {
  return GameCharacter.fromJson(<String, dynamic>{
    'id': id,
    'name': id,
    'title': 'Test character',
    'rarity': rarity.name,
    'description': 'Test description',
    'accent': 'FF799EC2',
    'pullable': pullable,
    'hidden': hidden,
    'portraitAsset': 'assets/overview.png',
    'mainAsset': 'assets/fullview.png',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('bundled catalog loads Axel and both bundled images', () async {
    final List<GameCharacter> roster = await loadCharacterRoster();
    expect(roster, hasLength(43));
    expect(roster.where((item) => item.pullable).map((item) => item.id), [
      'axel',
    ]);
    expect(roster.where((item) => !item.hidden).map((item) => item.id), [
      'axel',
    ]);
    final GameCharacter axel = roster.singleWhere((item) => item.id == 'axel');
    expect(axel.name, 'Axel');
    expect(axel.rarity, CharacterRarity.common);
    expect(axel.description, contains('Skelly'));
    expect(
      (await rootBundle.load(axel.portraitAsset)).lengthInBytes,
      greaterThan(0),
    );
    expect(
      (await rootBundle.load(axel.mainAsset)).lengthInBytes,
      greaterThan(0),
    );
  });

  test('catalog rejects duplicate IDs and missing pullable flags', () {
    final List<dynamic> entries =
        jsonDecode('''[
      {"id":"same","name":"Test","title":"Test","rarity":"common",
       "description":"Test","accent":"FF799EC2","pullable":false,"hidden":false,
       "portraitAsset":"assets/overview.png","mainAsset":"assets/fullview.png"}
    ]''')
            as List<dynamic>;
    expect(parseCharacterRoster(jsonEncode(entries)).single.pullable, isFalse);
    expect(
      () => parseCharacterRoster(jsonEncode([entries.single, entries.single])),
      throwsFormatException,
    );
    (entries.single as Map<String, dynamic>).remove('pullable');
    expect(
      () => parseCharacterRoster(jsonEncode(entries)),
      throwsA(isA<TypeError>()),
    );
  });

  test('default roster preserves the original rarity rates', () {
    final SpiralAppState state = SpiralAppState(roster: testCharacterRoster);
    addTearDown(state.dispose);
    expect(state.gachaRates, <CharacterRarity, double>{
      CharacterRarity.common: 0.68,
      CharacterRarity.rare: 0.22,
      CharacterRarity.epic: 0.09,
      CharacterRarity.legendary: 0.01,
    });
  });

  test('normal, tutorial and pity draws exclude private characters', () {
    final List<GameCharacter> roster = <GameCharacter>[
      for (final CharacterRarity rarity in CharacterRarity.values) ...[
        character('pullable-${rarity.name}', rarity),
        character('private-${rarity.name}', rarity, pullable: false),
      ],
    ];
    final SpiralAppState state = SpiralAppState(roster: roster);
    addTearDown(state.dispose);
    state.bits = SpiralAppState.pullCost * 200;
    final List<GameCharacter> results = state.pullCharacters(100)!;
    expect(results.every((item) => item.pullable), isTrue);
    expect(state.tutorialDrawOne().single.pullable, isTrue);
    state.pityCounter = SpiralAppState.pityLimit - 1;
    expect(state.pullCharacter()!.id, 'pullable-legendary');
    expect(state.pityCounter, 0);
    expect(state.findCharacterById('private-common'), isNotNull);
    expect(
      state.collection.keys.every((id) => id.startsWith('pullable-')),
      isTrue,
    );
  });

  test(
    'a single pullable rarity remains drawable and preserves legendary pity',
    () {
      final SpiralAppState state = SpiralAppState(
        roster: <GameCharacter>[
          character('axel', CharacterRarity.common),
          character('hidden', CharacterRarity.legendary, pullable: false),
        ],
      );
      addTearDown(state.dispose);
      state.bits = SpiralAppState.pullCost * 10;
      state.pityCounter = SpiralAppState.pityLimit - 1;
      expect(
        state.pullCharacters(10)!.every((item) => item.id == 'axel'),
        isTrue,
      );
      expect(state.pityCounter, SpiralAppState.pityLimit + 9);
      expect(state.gachaRates[CharacterRarity.common], 1);
      expect(state.gachaRates[CharacterRarity.legendary], 0);
    },
  );

  test(
    'an empty pullable pool does not spend or award bits or change pity',
    () {
      final SpiralAppState state = SpiralAppState(
        roster: <GameCharacter>[
          character('hidden', CharacterRarity.common, pullable: false),
        ],
      );
      addTearDown(state.dispose);
      state.bits = SpiralAppState.pullCost * 10;
      state.pityCounter = 99;
      expect(state.pullCharacters(10), isNull);
      expect(state.tutorialDrawOne(), isEmpty);
      expect(state.bits, SpiralAppState.pullCost * 10);
      expect(state.pityCounter, 99);
      expect(state.totalPulls, 0);
      expect(state.collection, isEmpty);
      state.bits = 0;
      expect(state.tutorialDrawOne(), isEmpty);
      expect(state.bits, 0);
    },
  );

  test(
    'visibility and pullability are independent, with hidden overriding draws',
    () {
      final SpiralAppState state = SpiralAppState(
        roster: [
          character('active', CharacterRarity.common),
          character('display-only', CharacterRarity.rare, pullable: false),
          character('hidden', CharacterRarity.legendary, hidden: true),
        ],
      );
      addTearDown(state.dispose);
      expect(state.roster.map((item) => item.id), ['active', 'display-only']);
      expect(state.gachaPool.map((item) => item.id), ['active']);
      expect(state.visibleCharacterById('hidden'), isNull);
      state.bits = 1000;
      state.pityCounter = 99;
      expect(
        state.pullCharacters(10)!.every((item) => item.id == 'active'),
        isTrue,
      );
      expect(state.hasPullableLegendary, isFalse);
    },
  );

  test(
    'live catalog changes preserve ownership and refresh pools and recent pulls',
    () {
      final GameCharacter active = character('active', CharacterRarity.common);
      final SpiralAppState state = SpiralAppState(roster: [active]);
      addTearDown(state.dispose);
      state.bits = 100;
      state.pullCharacter();
      int changes = 0;
      state.addListener(() => changes++);
      state.updateCharacterRoster([
        character('active', CharacterRarity.common, hidden: true),
      ]);
      expect(state.roster, isEmpty);
      expect(state.gachaPool, isEmpty);
      expect(state.collectedCount, 0);
      expect(state.collection['active'], 1);
      expect(state.lastPulledCharacter, isNull);
      expect(state.lastPulledCharacters, isEmpty);
      final GameCharacter revised = GameCharacter.fromJson({
        ...active.toJson(),
        'name': 'Revised name',
        'rarity': 'legendary',
      });
      state.updateCharacterRoster([revised]);
      expect(state.collectedCount, 1);
      expect(state.collectionProgress, 1);
      expect(state.lastPulledCharacter!.name, 'Revised name');
      expect(state.lastPulledCharacters.single.name, 'Revised name');
      expect(state.hasPullableLegendary, isTrue);
      expect(changes, 2);
    },
  );

  test(
    'cached catalog wins over bundled data, including an empty catalog',
    () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final GameCharacter remote = character('remote', CharacterRarity.epic);
      await prefs.setString(
        characterCatalogCacheKey,
        jsonEncode([remote.toJson()]),
      );
      expect((await loadCharacterRoster()).single.id, 'remote');
      await prefs.setString(characterCatalogCacheKey, '[]');
      expect(await loadCharacterRoster(), isEmpty);
      await prefs.setString(characterCatalogCacheKey, '{bad json');
      expect(
        (await loadCharacterRoster()).where((item) => !item.hidden).single.id,
        'axel',
      );
    },
  );

  test(
    'Firestore updates cache valid catalogs and recover after invalid data',
    () async {
      final controller = StreamController<Map<String, dynamic>?>();
      final Stream<List<GameCharacter>> updates = watchCharacterRoster(
        documents: controller.stream,
      );
      final SpiralAppState state = SpiralAppState(
        roster: bundledCharacterRoster,
        characterUpdates: updates,
      );
      addTearDown(state.dispose);
      final firstUpdate = Completer<void>();
      final emptyUpdate = Completer<void>();
      state.addListener(() {
        if (state.roster.isEmpty && !emptyUpdate.isCompleted) {
          emptyUpdate.complete();
        }
        if (state.roster.any((item) => item.id == 'remote') &&
            !firstUpdate.isCompleted) {
          firstUpdate.complete();
        }
      });
      controller.add(null); // Missing document keeps the bundled catalog.
      controller.add({'schemaVersion': 2, 'characters': []});
      controller.add({
        'schemaVersion': 1,
        'characters': [character('remote', CharacterRarity.rare).toJson()],
      });
      await firstUpdate.future.timeout(const Duration(seconds: 5));
      expect(state.roster.single.id, 'remote');
      expect((await loadCharacterRoster()).single.id, 'remote');
      controller.add({'schemaVersion': 1, 'characters': []});
      await emptyUpdate.future.timeout(const Duration(seconds: 5));
      expect(await loadCharacterRoster(), isEmpty);
      await controller.close();
    },
  );

  test('remote artwork round trips and rejects non-HTTPS URLs', () {
    final Map<String, dynamic> json =
        character('remote', CharacterRarity.common).toJson()
          ..['portraitUrl'] = 'https://example.com/portrait.jpg'
          ..['mainUrl'] = 'https://example.com/full.jpg';
    expect(GameCharacter.fromJson(json).toJson(), json);
    json['mainUrl'] = 'http://example.com/full.jpg';
    expect(() => GameCharacter.fromJson(json), throwsFormatException);
  });

  testWidgets('hidden characters disappear from the grid and an open profile', (
    tester,
  ) async {
    final GameCharacter active = character('active', CharacterRarity.common);
    final SpiralAppState state = SpiralAppState(
      roster: [
        active,
        character('hidden', CharacterRarity.common, hidden: true),
      ],
    );
    addTearDown(state.dispose);
    state.bits = 100;
    state.pullCharacter();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterRosterGrid(appState: state, onCharacterTap: (_, _) {}),
        ),
      ),
    );
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Unknown'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterDetailScreen(appState: state, character: active),
      ),
    );
    state.updateCharacterRoster([
      character('active', CharacterRarity.common, hidden: true),
    ]);
    await tester.pump();
    expect(find.text('Character unavailable'), findsOneWidget);
    expect(find.byType(CharacterImage), findsNothing);
    expect(find.text('active'), findsNothing);
  });
}
