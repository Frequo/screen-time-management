import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';

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
                      ],
                    ),
                  ),
                ),
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
