import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/cutscenescreen.dart';

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: const Color(0xFF2E4051),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Character Banner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trade hard-earned bits for pulls and fill your modern city roster.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _BannerStat(label: 'Bits', value: '${appState.bits}'),
                      _BannerStat(
                        label: 'Pull cost',
                        value: '${SpiralAppState.pullCost}',
                      ),
                      _BannerStat(
                        label: 'Collection',
                        value: '${appState.collectedCount}/42',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _handlePull(context, 1),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Draw 1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _handlePull(context, 10),
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Draw 10'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PityBar(appState: appState),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Rates and pity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Common 68%  |  Rare 22%  |  Epic 9%  |  Legendary 1%',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every 100 pulls guarantees a legendary. Missing characters are slightly favored within each rarity pool.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Card(
            //   child: Padding(
            //     padding: const EdgeInsets.all(20),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: <Widget>[
            //         Text(
            //           'Featured legendary set',
            //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
            //             fontWeight: FontWeight.w700,
            //           ),
            //         ),
            //         const SizedBox(height: 12),
            //         for (final GameCharacter character
            //             in appState
            //                 .charactersByRarity(CharacterRarity.legendary)
            //                 .take(3))
            //           Padding(
            //             padding: const EdgeInsets.only(bottom: 12),
            //             child: _CharacterPreviewTile(
            //               character: character,
            //               copies: appState.copiesOwned(character),
            //             ),
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
            if (appState.lastPulledCharacter != null) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Most recent pull',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CharacterPreviewTile(
                        character: appState.lastPulledCharacter!,
                        copies: appState.copiesOwned(
                          appState.lastPulledCharacter!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _handlePull(BuildContext context, int count) {
    final List<GameCharacter>? results = appState.pullCharacters(count);
    if (results == null || results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 10
                ? 'You need ${SpiralAppState.pullCost * 10} bits for a 10-pull.'
                : 'Not enough bits yet. Finish another focus session first.',
          ),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/cutscene',
      arguments: CutsceneArgs(
        characters: results,
        currentIndex: 0,
        allowSkip: count > 1,
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PityBar extends StatelessWidget {
  const _PityBar({required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Pity left',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${appState.pityRemaining} until guaranteed legendary',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: Colors.white24),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: appState.pityProgress,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Color(0xFFFFD36A), Color(0xFFE4A11B)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterPreviewTile extends StatelessWidget {
  const _CharacterPreviewTile({required this.character, required this.copies});

  final GameCharacter character;
  final int copies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: character.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.accent,
            ),
            child: ClipOval(
              child: Image.asset(character.portraitAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${character.name}  ·  ${character.title}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(copies > 0 ? 'x$copies' : character.rarity.label),
        ],
      ),
    );
  }

  IconData _rarityIcon(CharacterRarity rarity) {
    return switch (rarity) {
      CharacterRarity.common => Icons.person,
      CharacterRarity.rare => Icons.flash_on_rounded,
      CharacterRarity.epic => Icons.local_fire_department_rounded,
      CharacterRarity.legendary => Icons.stars_rounded,
    };
  }
}
