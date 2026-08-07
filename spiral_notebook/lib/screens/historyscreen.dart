import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/app_bar_settings_action.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        final List<FocusSessionRecord> history = appState.sessionHistory;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Focus history'),
            actions: const <Widget>[AppBarSettingsAction(), SizedBox(width: 8)],
          ),
          body: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: <Widget>[
                DailyProgressCard(appState: appState),
                const SizedBox(height: 16),
                _StreakCard(appState: appState),
                const SizedBox(height: 16),
                _WeeklyChartCard(appState: appState),
                const SizedBox(height: 16),
                _LifetimeCard(appState: appState),
                const SizedBox(height: 16),
                _SessionLogCard(appState: appState, history: history),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Today's minutes against the daily target from Settings. Shared with the
/// Inventory tab so the target slider has a visible effect in both places.
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.appState,
    this.onTap,
    this.showStreak = false,
  });

  final SpiralAppState appState;
  final VoidCallback? onTap;
  final bool showStreak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int today = appState.todayFocusMinutes;
    final int target = appState.dailyTargetMinutes;
    final bool met = appState.isDailyTargetMet;

    final Widget content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Today',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (met)
                const _Badge(
                  icon: Icons.check_circle_rounded,
                  label: 'Target met',
                  color: AppPalette.mint,
                )
              else if (showStreak && appState.currentStreakDays > 0)
                _Badge(
                  icon: Icons.local_fire_department_rounded,
                  label: '${appState.currentStreakDays}d streak',
                  color: AppPalette.tangerine,
                ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '$today',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              // Flexible: at 320pt the target line has to be able to shrink,
              // otherwise the row overflows on the narrowest supported phones.
              Flexible(
                child: Text(
                  'of $target min today',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: appState.dailyProgress,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.10,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                met ? AppPalette.mint : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            met
                ? 'Daily target reached. Anything else today is a bonus.'
                : '${appState.minutesLabel(appState.dailyMinutesRemaining)} left to hit today’s target.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Card(child: content);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Metric(
                icon: Icons.local_fire_department_rounded,
                color: AppPalette.tangerine,
                value: '${appState.currentStreakDays}',
                label: 'day streak',
              ),
            ),
            Container(
              width: 1,
              height: 54,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
            Expanded(
              child: _Metric(
                icon: Icons.emoji_events_rounded,
                color: AppPalette.sun,
                value: '${appState.longestStreakDays}',
                label: 'best streak',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.appState});

  final SpiralAppState appState;

  static const List<String> _weekdayLabels = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<DailyFocusTotal> week = appState.recentDailyTotals();
    final int weekMinutes = week.fold<int>(
      0,
      (int total, DailyFocusTotal day) => total + day.minutes,
    );
    // Scale bars against the busiest day, but never below the daily target, so
    // a light week doesn't render as if every day were a full one.
    final int peak = week.fold<int>(
      appState.dailyTargetMinutes,
      (int highest, DailyFocusTotal day) =>
          day.minutes > highest ? day.minutes : highest,
    );
    final DateTime today = appState.todayDate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Last 7 days',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  appState.minutesLabel(weekMinutes),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: week.map((DailyFocusTotal day) {
                  final bool isToday = day.date == today;
                  final double fraction = peak == 0
                      ? 0
                      : (day.minutes / peak).clamp(0, 1).toDouble();

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            day.minutes == 0 ? '' : '${day.minutes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: LayoutBuilder(
                              builder:
                                  (
                                    BuildContext context,
                                    BoxConstraints constraints,
                                  ) {
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        // Keep a sliver visible on empty days
                                        // so the axis reads as a full week.
                                        height:
                                            4 +
                                            (constraints.maxHeight - 4) *
                                                fraction,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: day.minutes == 0
                                              ? theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.12)
                                              : isToday
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                    .withValues(alpha: 0.55),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _weekdayLabels[day.date.weekday - 1],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'All time',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _StatChip(
                  label: 'Total focused',
                  value: appState.minutesLabel(appState.totalFocusMinutes),
                ),
                _StatChip(
                  label: 'Best run',
                  value: appState.formatDuration(appState.bestSessionSeconds),
                ),
                _StatChip(
                  label: 'Sessions logged',
                  value: '${appState.loggedSessionCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionLogCard extends StatelessWidget {
  const _SessionLogCard({required this.appState, required this.history});

  final SpiralAppState appState;
  final List<FocusSessionRecord> history;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Session log',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              history.isEmpty
                  ? 'Finish a focus session and it will show up here.'
                  : 'Your ${history.length} most recent sessions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No sessions yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final FocusSessionRecord record in history)
                _SessionTile(appState: appState, record: record),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.appState, required this.record});

  final SpiralAppState appState;
  final FocusSessionRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (record.metTarget ? AppPalette.mint : AppPalette.sky)
                  .withValues(alpha: 0.18),
            ),
            child: Icon(
              record.metTarget
                  ? Icons.check_rounded
                  : Icons.hourglass_bottom_rounded,
              color: record.metTarget ? AppPalette.mint : AppPalette.sky,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.label.isEmpty ? 'Focus session' : record.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTimestamp(record.completedAt, appState.todayDate)} · ${record.difficulty.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                appState.minutesLabel(record.wholeMinutes),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+${record.bitsEarned} bits',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.tangerine,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime value, DateTime today) {
  final DateTime day = DateTime(value.year, value.month, value.day);
  final int daysAgo = today.difference(day).inDays;

  final String time = TimeOfDayFormatting.format(value);
  if (daysAgo == 0) {
    return 'Today, $time';
  }
  if (daysAgo == 1) {
    return 'Yesterday, $time';
  }
  return '${_monthNames[value.month - 1]} ${value.day}, $time';
}

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Minimal 12-hour clock formatting. The app has no intl dependency, and this
/// only ever renders timestamps the user themselves generated.
class TimeOfDayFormatting {
  const TimeOfDayFormatting._();

  static String format(DateTime value) {
    final int rawHour = value.hour % 12;
    final int hour = rawHour == 0 ? 12 : rawHour;
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
