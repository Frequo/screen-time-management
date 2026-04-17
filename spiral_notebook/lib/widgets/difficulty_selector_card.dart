import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';

class DifficultySelectorCard extends StatelessWidget {
  const DifficultySelectorCard({
    super.key,
    required this.appState,
    this.title = 'Difficulty and rewards',
    this.description =
        'Choose the workload tier you want this session to represent. Harder tiers slow down your bit gain.',
    this.padding = const EdgeInsets.all(20),
  });

  final SpiralAppState appState;
  final String title;
  final String description;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color activeTileColor = isDark
        ? AppPalette.sky.withValues(alpha: 0.22)
        : AppPalette.sky.withValues(alpha: 0.14);
    final Color activeCollegeTileColor = isDark
        ? AppPalette.tangerine.withValues(alpha: 0.24)
        : AppPalette.sun.withValues(alpha: 0.42);
    final Color inactiveTileColor = isDark
        ? AppPalette.night.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.54);
    final Color tileTextColor = isDark ? Colors.white : AppPalette.ink;
    final Color tileSubtextColor = isDark
        ? AppPalette.nightMuted
        : AppPalette.inkMuted;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
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
                                ? activeCollegeTileColor
                                : activeTileColor
                          : inactiveTileColor,
                      border: Border.all(
                        color: option == appState.difficulty
                            ? theme.colorScheme.primary
                            : isDark
                            ? const Color(0xFF1A4666)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                option.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: tileTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tileSubtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              '${option.rewardPerMinute}/min',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tileTextColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (option == appState.difficulty)
                              Text(
                                'Active',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tileSubtextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
    );
  }
}
