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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFF8EFE3), Color(0xFFE5F1ED)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Card(
                  child: SwitchListTile(
                    value: appState.soundEnabled,
                    onChanged: appState.setSoundEnabled,
                    title: const Text('Sound effects'),
                    subtitle: const Text(
                      'Play banner and session feedback sounds.',
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
