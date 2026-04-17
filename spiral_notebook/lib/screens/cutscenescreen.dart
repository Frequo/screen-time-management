import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/rarity_backdrop.dart';

class CutsceneArgs {
  const CutsceneArgs({
    required this.characters,
    this.currentIndex = 0,
    this.allowSkip = false,
  });

  final List<GameCharacter> characters;
  final int currentIndex;
  final bool allowSkip;
}

class PullResultsArgs {
  const PullResultsArgs({required this.characters});

  final List<GameCharacter> characters;
}

class CutsceneScreen extends StatefulWidget {
  const CutsceneScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  State<CutsceneScreen> createState() => _CutsceneScreenState();
}

class _CutsceneScreenState extends State<CutsceneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _revealTimer;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _startRevealTimer();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CutsceneArgs args = _resolvedArgs(context);
    if (args.characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No pull result available.')),
      );
    }

    final int currentIndex = args.currentIndex.clamp(
      0,
      args.characters.length - 1,
    );
    final GameCharacter character = args.characters[currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: args.allowSkip && args.characters.length > 1
            ? <Widget>[
                TextButton(
                  onPressed: () => _openResults(context, args.characters),
                  child: const Text('Skip all'),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: RarityBackdrop(
        rarity: character.rarity,
        accent: character.accent,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                child: _revealed
                    ? _RevealCard(
                        character: character,
                        appState: widget.appState,
                        currentIndex: currentIndex,
                        characters: args.characters,
                        allowSkip: args.allowSkip,
                        onNext: () => _openNext(context, args, currentIndex),
                        onOpenResults: () =>
                            _openResults(context, args.characters),
                      )
                    : _HourglassAnimation(
                        controller: _controller,
                        currentIndex: currentIndex,
                        totalCount: args.characters.length,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CutsceneArgs _resolvedArgs(BuildContext context) {
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is CutsceneArgs) {
      return arguments;
    }

    if (widget.appState.lastPulledCharacters.isNotEmpty) {
      return CutsceneArgs(
        characters: widget.appState.lastPulledCharacters,
        allowSkip: widget.appState.lastPulledCharacters.length > 1,
      );
    }

    final GameCharacter? lastCharacter = widget.appState.lastPulledCharacter;
    return CutsceneArgs(
      characters: lastCharacter == null
          ? <GameCharacter>[]
          : <GameCharacter>[lastCharacter],
    );
  }

  void _startRevealTimer() {
    _revealTimer?.cancel();
    _revealed = false;
    _controller.repeat(reverse: true);
    _revealTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _revealed = true;
      });
      _controller.stop();
    });
  }

  void _openNext(BuildContext context, CutsceneArgs args, int currentIndex) {
    if (currentIndex >= args.characters.length - 1) {
      if (args.characters.length > 1) {
        _openResults(context, args.characters);
      } else {
        Navigator.pop(context);
      }
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/cutscene',
      arguments: CutsceneArgs(
        characters: args.characters,
        currentIndex: currentIndex + 1,
        allowSkip: args.allowSkip,
      ),
    );
  }

  void _openResults(BuildContext context, List<GameCharacter> characters) {
    Navigator.pushReplacementNamed(
      context,
      '/pull-results',
      arguments: PullResultsArgs(characters: characters),
    );
  }
}

class _HourglassAnimation extends StatelessWidget {
  const _HourglassAnimation({
    required this.controller,
    required this.currentIndex,
    required this.totalCount,
  });

  final AnimationController controller;
  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('hourglass'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RotationTransition(
          turns: Tween<double>(begin: -0.03, end: 0.03).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
          child: const Icon(
            Icons.hourglass_bottom_rounded,
            size: 140,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          totalCount > 1
              ? 'Reveal ${currentIndex + 1} of $totalCount'
              : 'The sand is settling...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({
    required this.character,
    required this.appState,
    required this.currentIndex,
    required this.characters,
    required this.allowSkip,
    required this.onNext,
    required this.onOpenResults,
  });

  final GameCharacter character;
  final SpiralAppState appState;
  final int currentIndex;
  final List<GameCharacter> characters;
  final bool allowSkip;
  final VoidCallback onNext;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    final bool hasMore = currentIndex < characters.length - 1;
    final bool isBatch = characters.length > 1;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color rarityAccent = character.rarity.color;
    final Color surfaceAccent = _darkRollSurfaceAccent(character.rarity);

    return Container(
      key: ValueKey<String>('reveal-${character.id}-$currentIndex'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xEE0B2435)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? surfaceAccent : rarityAccent).withValues(
            alpha: isDark ? 0.8 : 0.3,
          ),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isBatch)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Pull ${currentIndex + 1} of ${characters.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? AppPalette.nightMuted : Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.accent,
            ),
            child: ClipOval(
              child: Image.asset(character.portraitAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            character.rarity.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: rarityAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            character.name,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(character.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            character.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/character',
                    arguments: character.id,
                  ),
                  child: const Text('View character'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: onNext,
                  child: Text(
                    hasMore
                        ? 'Next reveal'
                        : isBatch
                        ? 'See all results'
                        : 'Back to banner',
                  ),
                ),
              ),
            ],
          ),
          if (allowSkip && hasMore) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onOpenResults,
              child: const Text('Skip remaining reveals'),
            ),
          ],
          const SizedBox(height: 8),
          Text('Owned copies: x${appState.copiesOwned(character)}'),
        ],
      ),
    );
  }
}

class PullResultsScreen extends StatelessWidget {
  const PullResultsScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    final List<GameCharacter> characters = arguments is PullResultsArgs
        ? arguments.characters
        : appState.lastPulledCharacters;

    if (characters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pull results')),
        body: const Center(child: Text('No pull results available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Results (${characters.length})')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemCount: characters.length,
                itemBuilder: (BuildContext context, int index) {
                  final GameCharacter character = characters[index];
                  final _ResultCardPalette palette = _resultPaletteFor(
                    character.rarity,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  );
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/character',
                      arguments: character.id,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: palette.base,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: palette.border, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: 88,
                              width: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: character.accent,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  character.portraitAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              character.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              character.rarity.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: palette.spark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Owned x${appState.copiesOwned(character)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.subtext),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.popUntil(
                  context,
                  (Route<dynamic> route) => route.isFirst,
                ),
                child: const Text('Back to banner'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCardPalette {
  const _ResultCardPalette({
    required this.base,
    required this.border,
    required this.spark,
    required this.text,
    required this.subtext,
  });

  final Color base;
  final Color border;
  final Color spark;
  final Color text;
  final Color subtext;
}

_ResultCardPalette _resultPaletteFor(
  CharacterRarity rarity, {
  required bool isDark,
}) {
  if (isDark) {
    return switch (rarity) {
      CharacterRarity.common => const _ResultCardPalette(
        base: Color(0xFF0A2C3C),
        border: AppPalette.darkRollCommon,
        spark: AppPalette.sky,
        text: Color(0xFFE2FFF7),
        subtext: Color(0xFFA9E7D4),
      ),
      CharacterRarity.rare => const _ResultCardPalette(
        base: Color(0xFF08253A),
        border: AppPalette.darkRollRare,
        spark: AppPalette.mint,
        text: Color(0xFFE0F4FF),
        subtext: Color(0xFF8EC9E7),
      ),
      CharacterRarity.epic => const _ResultCardPalette(
        base: Color(0xFF2F1806),
        border: AppPalette.darkRollEpic,
        spark: AppPalette.tangerine,
        text: Color(0xFFFFEBD9),
        subtext: Color(0xFFD7A777),
      ),
      CharacterRarity.legendary => const _ResultCardPalette(
        base: Color(0xFF241028),
        border: AppPalette.darkRollLegendary,
        spark: AppPalette.sun,
        text: Color(0xFFF7E6FF),
        subtext: Color(0xFFC999D1),
      ),
    };
  }

  return switch (rarity) {
    CharacterRarity.common => const _ResultCardPalette(
      base: Color(0xFFE6F7FF),
      border: Color(0xFF0C4A6E),
      spark: AppPalette.sky,
      text: Color(0xFF10314A),
      subtext: Color(0xFF466276),
    ),
    CharacterRarity.rare => const _ResultCardPalette(
      base: Color(0xFFE7FFF6),
      border: Color(0xFF0A4B3B),
      spark: AppPalette.mint,
      text: Color(0xFF11372D),
      subtext: Color(0xFF3B756A),
    ),
    CharacterRarity.epic => const _ResultCardPalette(
      base: Color(0xFFFFF0E1),
      border: Color(0xFF7A4300),
      spark: AppPalette.tangerine,
      text: Color(0xFF5B3200),
      subtext: Color(0xFF966233),
    ),
    CharacterRarity.legendary => const _ResultCardPalette(
      base: Color(0xFFFFF8CC),
      border: Color(0xFF674D00),
      spark: AppPalette.sun,
      text: Color(0xFF5C4300),
      subtext: Color(0xFF927238),
    ),
  };
}

Color _darkRollSurfaceAccent(CharacterRarity rarity) {
  return switch (rarity) {
    CharacterRarity.common => AppPalette.darkRollCommon,
    CharacterRarity.rare => AppPalette.darkRollRare,
    CharacterRarity.epic => AppPalette.darkRollEpic,
    CharacterRarity.legendary => AppPalette.darkRollLegendary,
  };
}
