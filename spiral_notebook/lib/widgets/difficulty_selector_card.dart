import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

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
        ? const Color(0xFF22353B)
        : const Color(0xFFE7F3EF);
    final Color activeCollegeTileColor = isDark
        ? const Color(0xFF243241)
        : const Color(0xFFE2EDF6);
    final Color inactiveTileColor = isDark
        ? const Color(0xFF1B2730)
        : const Color(0xFFF4F8F6);
    final Color tileTextColor = isDark
        ? const Color(0xFFF2F7F6)
        : const Color(0xFF182127);
    final Color tileSubtextColor = isDark
        ? const Color(0xFFB8CAC8)
        : const Color(0xFF5B696B);

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
                            ? const Color(0xFF223038)
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
