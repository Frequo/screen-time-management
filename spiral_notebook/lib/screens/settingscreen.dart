import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/widgets/difficulty_selector_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final SpiralAppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          appState.playerName.isEmpty
                              ? 'Nexi account'
                              : appState.playerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (appState.playerEmail.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(appState.playerEmail),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await appState.logout();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: const Text('Switch account'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: <ThemeMode>{appState.themeMode},
                          onSelectionChanged: (Set<ThemeMode> selection) {
                            appState.setThemeMode(selection.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Accent color',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick the highlight color used for buttons, active states, and selections.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppAccentStyle.values
                              .map((AppAccentStyle style) {
                                return _AccentStyleChip(
                                  style: style,
                                  isSelected: appState.accentStyle == style,
                                  onSelected: () =>
                                      appState.setAccentStyle(style),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DifficultySelectorCard(appState: appState),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: appState.soundEnabled,
                    onChanged: appState.setSoundEnabled,
                    title: const Text('App audio'),
                    subtitle: const Text(
                      'Turn this off to mute all app sound, including focus ambience.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: appState.ambientSoundsEnabled,
                    onChanged: appState.setAmbientSoundsEnabled,
                    title: const Text('Ambient focus audio'),
                    subtitle: const Text(
                      'Only plays during an active focus session and pauses with the timer.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: appState.hapticsEnabled,
                    onChanged: appState.setHapticsEnabled,
                    title: const Text('Haptics'),
                    subtitle: const Text(
                      'Use vibration cues when sessions end or pulls reveal.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    value: appState.reminderEnabled,
                    onChanged: appState.setReminderEnabled,
                    title: const Text('Stand reminders'),
                    subtitle: const Text(
                      'Keep reminding me to place the phone on the stand.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Daily target: ${appState.dailyTargetMinutes} min',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use this to tune how much focus time feels like a full day.',
                        ),
                        Slider(
                          min: 30,
                          max: 180,
                          divisions: 10,
                          label: '${appState.dailyTargetMinutes}',
                          value: appState.dailyTargetMinutes.toDouble(),
                          onChanged: (double value) =>
                              appState.setDailyTarget(value.round()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await appState.logout();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccentStyleChip extends StatelessWidget {
  const _AccentStyleChip({
    required this.style,
    required this.isSelected,
    required this.onSelected,
  });

  final AppAccentStyle style;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color previewColor = isDark ? style.darkPrimary : style.lightPrimary;
    final Color previewSecondary = isDark
        ? style.darkSecondary
        : style.lightSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onSelected,
      child: Ink(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.cardColor,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[previewColor, previewSecondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              style.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
