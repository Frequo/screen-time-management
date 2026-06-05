import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/app_bar_settings_action.dart';

class ConnectStandScreen extends StatelessWidget {
  const ConnectStandScreen({super.key, required this.appState});

  final SpiralAppState appState;

  static const String deviceName = 'FSR Phone';
  static const String serviceName = 'Nordic UART BLE service';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect stand'),
        actions: const <Widget>[AppBarSettingsAction(), SizedBox(width: 8)],
      ),
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppPalette.mint, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppPalette.mint.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: AppPalette.mint,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              deviceName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone stand sensor',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'The hardware advertises as FSR Phone and reports whether the phone is resting on the force sensor.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.bluetooth_searching_rounded),
                          label: const Text('Scan coming soon'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'BLE transport is not enabled in this Flutter build yet. This screen is wired for the CircuitPython protocol so the Bluetooth layer can plug in here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                      'Device protocol',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _ProtocolRow(
                      label: 'BLE name',
                      value: deviceName,
                      icon: Icons.bluetooth_rounded,
                    ),
                    const _ProtocolRow(
                      label: 'Service',
                      value: serviceName,
                      icon: Icons.settings_input_component_rounded,
                    ),
                    const _ProtocolRow(
                      label: 'Status command',
                      value: 'status',
                      icon: Icons.help_outline_rounded,
                    ),
                    const _ProtocolRow(
                      label: 'Calibrate command',
                      value: 'calibrate',
                      icon: Icons.speed_rounded,
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
                      'Messages from stand',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const <Widget>[
                        _MessageChip(label: 'PHONE_ON'),
                        _MessageChip(label: 'PHONE_OFF'),
                        _MessageChip(label: 'STATE'),
                        _MessageChip(label: 'CALIBRATED'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'STATE messages include phone_present, the current analog value, and the on/off thresholds.',
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
                      'Setup checklist',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _ChecklistItem(
                      text: 'Flash hardware/main.py to the QT Py ESP32-S3.',
                    ),
                    const _ChecklistItem(
                      text: 'Boot the board with the phone off the FSR.',
                    ),
                    const _ChecklistItem(
                      text: 'Wait for calibration, then place the phone down.',
                    ),
                    const _ChecklistItem(
                      text: 'Pair with the advertised FSR Phone device.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MessageChip extends StatelessWidget {
  const _MessageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.terminal_rounded, size: 18),
      label: Text(label),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.check_circle_outline_rounded, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
