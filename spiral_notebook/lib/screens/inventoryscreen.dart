import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/screens/characterview.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/difficulty_selector_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    super.key,
    required this.appState,
    required this.onStartFocus,
    required this.onOpenGacha,
    required this.onOpenSettings,
  });

  final SpiralAppState appState;
  final VoidCallback onStartFocus;
  final VoidCallback onOpenGacha;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: <Widget>[
            _HeroCard(appState: appState),
            const SizedBox(height: 16),
            DifficultySelectorCard(appState: appState),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Character roster',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your collection now lives here. Tap any character card to inspect the details.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    CharacterRosterGrid(
                      appState: appState,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onCharacterTap:
                          (BuildContext context, GameCharacter character) {
                            showCharacterDetailSheet(
                              context,
                              appState: appState,
                              character: character,
                            );
                          },
                    ),
                  ],
                ),
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
                      'Launch options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onStartFocus,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start focus session'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onOpenGacha,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Spend bits in gacha'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onOpenSettings,
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Open settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: theme.cardColor,
        border: Border.all(color: AppPalette.sky, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Backpack',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the phone down, pick a difficulty, and let your focus build the collection.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _StatPill(label: 'Bits', value: '${appState.bits}'),
              _StatPill(
                label: 'Collected',
                value: '${appState.collectedCount}/42',
              ),
              _StatPill(
                label: 'Focused',
                value: appState.minutesLabel(appState.totalFocusMinutes),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppPalette.sky.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppPalette.sky.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white : AppPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white : AppPalette.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
