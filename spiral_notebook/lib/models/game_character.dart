import 'package:flutter/material.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

enum CharacterRarity { common, rare, epic, legendary }

extension CharacterRarityDetails on CharacterRarity {
  String get label => switch (this) {
    CharacterRarity.common => 'Common',
    CharacterRarity.rare => 'Rare',
    CharacterRarity.epic => 'Epic',
    CharacterRarity.legendary => 'Legendary',
  };

  Color get color => switch (this) {
    CharacterRarity.common => AppPalette.sky,
    CharacterRarity.rare => AppPalette.mint,
    CharacterRarity.epic => AppPalette.tangerine,
    CharacterRarity.legendary => AppPalette.sun,
  };
}

class GameCharacter {
  const GameCharacter({
    required this.id,
    required this.name,
    required this.title,
    required this.rarity,
    required this.description,
    required this.accent,
    required this.pullable,
    required this.hidden,
    this.portraitAsset = 'assets/overview.png',
    this.mainAsset = 'assets/fullview.png',
    this.portraitUrl,
    this.mainUrl,
  });

  final String id;
  final String name;
  final String title;
  final CharacterRarity rarity;
  final String description;
  final Color accent;

  /// Whether this character can be drawn from the gacha pool.
  final bool pullable;

  /// Hidden characters do not appear in the UI or in draws.
  final bool hidden;
  final String portraitAsset;
  final String mainAsset;
  final String? portraitUrl;
  final String? mainUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'title': title,
    'rarity': rarity.name,
    'description': description,
    'accent': accent.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase(),
    'pullable': pullable,
    'hidden': hidden,
    'portraitAsset': portraitAsset,
    'mainAsset': mainAsset,
    if (portraitUrl != null) 'portraitUrl': portraitUrl,
    if (mainUrl != null) 'mainUrl': mainUrl,
  };

  factory GameCharacter.fromJson(Map<String, dynamic> json) {
    final String accent = json['accent'] as String;
    if (!RegExp(r'^[0-9A-Fa-f]{8}$').hasMatch(accent)) {
      throw FormatException('Character accent must be eight ARGB hex digits');
    }
    return GameCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      rarity: CharacterRarity.values.byName(json['rarity'] as String),
      description: json['description'] as String,
      accent: Color(int.parse(accent, radix: 16)),
      pullable: json['pullable'] as bool,
      hidden: json['hidden'] as bool,
      portraitAsset: json['portraitAsset'] as String? ?? 'assets/overview.png',
      mainAsset: json['mainAsset'] as String? ?? 'assets/fullview.png',
      portraitUrl: _imageUrl(json['portraitUrl']),
      mainUrl: _imageUrl(json['mainUrl']),
    );
  }

  static String? _imageUrl(Object? value) {
    if (value == null) return null;
    final Uri? uri = Uri.tryParse(value as String);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('Character image URLs must use HTTPS');
    }
    return value;
  }
}
