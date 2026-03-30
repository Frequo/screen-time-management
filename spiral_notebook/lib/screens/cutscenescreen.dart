import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/widgets/rarity_backdrop.dart';

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

  @override
  void dispose() {
    _revealTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GameCharacter? character = widget.appState.lastPulledCharacter;
    if (character == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No pull result available.')),
      );
    }

    return Scaffold(
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
                      )
                    : _HourglassAnimation(controller: _controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourglassAnimation extends StatelessWidget {
  const _HourglassAnimation({required this.controller});

  final AnimationController controller;

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
          'The sand is settling...',
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
  const _RevealCard({required this.character, required this.appState});

  final GameCharacter character;
  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('reveal'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.accent,
            ),
            child: Icon(
              _rarityIcon(character.rarity),
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            character.rarity.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: character.rarity.color,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to banner'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Owned copies: x${appState.copiesOwned(character)}'),
        ],
      ),
    );
  }
}

IconData _rarityIcon(CharacterRarity rarity) {
  return switch (rarity) {
    CharacterRarity.common => Icons.person,
    CharacterRarity.rare => Icons.flash_on_rounded,
    CharacterRarity.epic => Icons.local_fire_department_rounded,
    CharacterRarity.legendary => Icons.stars_rounded,
  };
}
