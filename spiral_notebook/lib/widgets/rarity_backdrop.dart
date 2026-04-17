import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

class RarityBackdrop extends StatelessWidget {
  const RarityBackdrop({
    super.key,
    required this.rarity,
    required this.accent,
    required this.child,
  });

  final CharacterRarity rarity;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _RarityPalette palette = _paletteFor(
      rarity,
      accent,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: palette.base),
        Positioned(
          top: -90,
          left: -60,
          child: _GlowOrb(size: 240, color: palette.primaryGlow),
        ),
        Positioned(
          top: 140,
          right: -70,
          child: _GlowOrb(size: 220, color: palette.secondaryGlow),
        ),
        Positioned(
          bottom: -110,
          left: 30,
          child: _GlowOrb(size: 280, color: palette.primaryGlow),
        ),
        Positioned(
          top: 90,
          left: 24,
          right: 24,
          child: _Band(color: palette.band, rotation: -0.18),
        ),
        Positioned(
          bottom: 110,
          left: 48,
          right: 48,
          child: _Band(
            color: palette.band.withValues(alpha: 0.18),
            rotation: 0.12,
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.color, required this.rotation});

  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color,
        ),
      ),
    );
  }
}

class _RarityPalette {
  const _RarityPalette({
    required this.base,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.band,
  });

  final Color base;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color band;
}

_RarityPalette _paletteFor(
  CharacterRarity rarity,
  Color accent, {
  required bool isDark,
}) {
  if (isDark) {
    return switch (rarity) {
      CharacterRarity.common => _RarityPalette(
        base: const Color(0xFF06283A),
        primaryGlow: AppPalette.darkRollCommon.withValues(alpha: 0.18),
        secondaryGlow: AppPalette.darkRollRare.withValues(alpha: 0.22),
        band: AppPalette.darkRollCommon.withValues(alpha: 0.14),
      ),
      CharacterRarity.rare => _RarityPalette(
        base: const Color(0xFF041F32),
        primaryGlow: AppPalette.darkRollRare.withValues(alpha: 0.28),
        secondaryGlow: AppPalette.darkRollCommon.withValues(alpha: 0.18),
        band: AppPalette.darkRollRare.withValues(alpha: 0.18),
      ),
      CharacterRarity.epic => _RarityPalette(
        base: const Color(0xFF2D1704),
        primaryGlow: AppPalette.darkRollEpic.withValues(alpha: 0.28),
        secondaryGlow: AppPalette.darkRollLegendary.withValues(alpha: 0.2),
        band: AppPalette.darkRollEpic.withValues(alpha: 0.18),
      ),
      CharacterRarity.legendary => _RarityPalette(
        base: const Color(0xFF1F0A24),
        primaryGlow: AppPalette.darkRollLegendary.withValues(alpha: 0.32),
        secondaryGlow: AppPalette.darkRollEpic.withValues(alpha: 0.18),
        band: AppPalette.darkRollLegendary.withValues(alpha: 0.2),
      ),
    };
  }

  return switch (rarity) {
    CharacterRarity.common => _RarityPalette(
      base: accent.withValues(alpha: 0.16),
      primaryGlow: accent.withValues(alpha: 0.18),
      secondaryGlow: Colors.white.withValues(alpha: 0.2),
      band: accent.withValues(alpha: 0.12),
    ),
    CharacterRarity.rare => _RarityPalette(
      base: AppPalette.mint.withValues(alpha: 0.12),
      primaryGlow: AppPalette.mint.withValues(alpha: 0.3),
      secondaryGlow: AppPalette.sky.withValues(alpha: 0.22),
      band: AppPalette.mint.withValues(alpha: 0.18),
    ),
    CharacterRarity.epic => _RarityPalette(
      base: AppPalette.tangerine.withValues(alpha: 0.12),
      primaryGlow: AppPalette.tangerine.withValues(alpha: 0.28),
      secondaryGlow: AppPalette.sun.withValues(alpha: 0.24),
      band: AppPalette.tangerine.withValues(alpha: 0.2),
    ),
    CharacterRarity.legendary => _RarityPalette(
      base: AppPalette.sun.withValues(alpha: 0.2),
      primaryGlow: AppPalette.sun.withValues(alpha: 0.32),
      secondaryGlow: AppPalette.tangerine.withValues(alpha: 0.24),
      band: AppPalette.sun.withValues(alpha: 0.22),
    ),
  };
}
