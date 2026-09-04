import 'dart:io';

import 'package:spiral_notebook/models/game_character.dart';
import 'package:spiral_notebook/services/character_catalog.dart';

final List<GameCharacter> bundledCharacterRoster = parseCharacterRoster(
  File(characterCatalogAsset).readAsStringSync(),
);

// A fully released catalog keeps existing economy and reveal tests independent
// of which characters are currently released in production.
final List<GameCharacter> testCharacterRoster = bundledCharacterRoster
    .map(
      (character) => GameCharacter.fromJson(<String, dynamic>{
        ...character.toJson(),
        'pullable': true,
        'hidden': false,
      }),
    )
    .toList(growable: false);
