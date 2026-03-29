import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    super.key,
    required this.appState,
    required this.onStartFocus,
    required this.onOpenGacha,
    required this.onOpenCollection,
  });

  final SpiralAppState appState;
  final VoidCallback onStartFocus;
  final VoidCallback onOpenGacha;
  final VoidCallback onOpenCollection;

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Difficulty and rewards',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the workload tier you want this session to represent. Harder tiers slow down your bit gain.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final AppDifficulty option in AppDifficulty.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => appState.setDifficulty(option),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: option == appState.difficulty
                                  ? option == AppDifficulty.college
                                        ? const Color(0xFFE2EDF6)
                                        : const Color(0xFFE7F3EF)
                                  : const Color(0xFFF4F8F6),
                              border: Border.all(
                                color: option == appState.difficulty
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        option.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(option.subtitle),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      '${option.rewardPerMinute}/min',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (option == appState.difficulty)
                                      const Text('Active'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
                            onPressed: onOpenCollection,
                            icon: const Icon(Icons.groups_rounded),
                            label: const Text('View character roster'),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFF23384A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Backpack',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the phone down, pick a difficulty, and let your focus build the collection.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
              _StatPill(
                label: 'Best run',
                value: appState.formatDuration(appState.bestSessionSeconds),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Daily target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${appState.dailyProgressMinutes}/${appState.dailyTargetMinutes} min',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: appState.dailyProgress.clamp(0, 1),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF83E0C1),
                  ),
                ),
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
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
