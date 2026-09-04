import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_notebook/models/game_character.dart';

const String characterCatalogAsset = 'assets/characters.json';
const String characterCatalogDocument = 'catalog/characters';
const String characterCatalogCacheKey = 'characters.catalog.v1';

Future<List<GameCharacter>> loadCharacterRoster({
  AssetBundle? bundle,
  bool useCache = true,
}) async {
  if (useCache) {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(characterCatalogCacheKey);
      if (cached != null) return parseCharacterRoster(cached);
    } catch (error) {
      debugPrint('Character catalog cache unavailable: $error');
    }
  }
  return parseCharacterRoster(
    await (bundle ?? rootBundle).loadString(characterCatalogAsset),
  );
}

/// A whole catalog is published atomically, including deliberately empty lists.
/// Missing or malformed documents never replace the last usable catalog.
Stream<List<GameCharacter>> watchCharacterRoster({
  FirebaseFirestore? firestore,
  Stream<Map<String, dynamic>?>? documents,
}) {
  final Stream<Map<String, dynamic>?> updates =
      documents ??
      (firestore ?? FirebaseFirestore.instance)
          .doc(characterCatalogDocument)
          .snapshots()
          .map((snapshot) => snapshot.data());
  return updates.where((data) => data != null).asyncMap((data) async {
    final List<GameCharacter> roster = parseCharacterCatalogDocument(data!);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        characterCatalogCacheKey,
        jsonEncode(roster.map((character) => character.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Could not cache character catalog: $error');
    }
    return roster;
  });
}

List<GameCharacter> parseCharacterCatalogDocument(Map<String, dynamic> data) {
  if (data['schemaVersion'] != 1 || data['characters'] is! List) {
    throw FormatException('Unsupported character catalog document');
  }
  return parseCharacterRoster(jsonEncode(data['characters']));
}

List<GameCharacter> parseCharacterRoster(String source) {
  final List<dynamic> entries = jsonDecode(source) as List<dynamic>;
  final Set<String> ids = <String>{};
  final List<GameCharacter> characters = <GameCharacter>[];
  for (final dynamic entry in entries) {
    final GameCharacter character = GameCharacter.fromJson(
      entry as Map<String, dynamic>,
    );
    if (character.id.trim().isEmpty || !ids.add(character.id)) {
      throw FormatException('Empty or duplicate character ID: ${character.id}');
    }
    characters.add(character);
  }
  return List<GameCharacter>.unmodifiable(characters);
}
