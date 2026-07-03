import 'package:flutter/material.dart';
import 'package:spiral_notebook/app_state.dart';
import 'package:spiral_notebook/services/phone_stand_ble.dart';
import 'package:spiral_notebook/theme/app_palette.dart';
import 'package:spiral_notebook/widgets/app_bar_settings_action.dart';

class ConnectStandScreen extends StatelessWidget {
  const ConnectStandScreen({
    super.key,
    required this.appState,
    this.phoneStandController,
  });

  final SpiralAppState appState;
  final PhoneStandBleController? phoneStandController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect stand'),
        actions: const <Widget>[AppBarSettingsAction(), SizedBox(width: 8)],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          appState,
          ?phoneStandController,
        ]),
        builder: (BuildContext context, Widget? child) {
          final PhoneStandConnectionStatus status =
              appState.phoneStandConnectionStatus;
          final bool connected = appState.isPhoneStandConnected;
          final bool busy = phoneStandController?.isBusy ?? false;
          final bool canControl = phoneStandController != null && !busy;

          return ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: connected && appState.isPhoneOnStand
                          ? AppPalette.mint
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
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
                              color: _statusColor(
                                appState,
                              ).withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _statusIcon(appState),
                              color: _statusColor(appState),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  PhoneStandBleController.deviceName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.label,
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
                      Text(
                        _standPrompt(appState),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: canControl && !connected
                                ? phoneStandController!.connect
                                : null,
                            icon: busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.bluetooth_searching_rounded),
                            label: Text(
                              busy
                                  ? 'Working'
                                  : connected
                                  ? 'Connected'
                                  : 'Connect stand',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: canControl && connected
                                ? phoneStandController!.requestStatus
                                : null,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Status'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canControl && connected
                                ? phoneStandController!.calibrate
                                : null,
                            icon: const Icon(Icons.speed_rounded),
                            label: const Text('Calibrate'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canControl && connected
                                ? phoneStandController!.disconnect
                                : null,
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('Disconnect'),
                          ),
                        ],
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
                          'Live sensor',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ProtocolRow(
                          label: 'Phone',
                          value: appState.isPhoneOnStand
                              ? 'On stand'
                              : 'Off stand',
                          icon: appState.isPhoneOnStand
                              ? Icons.phone_android_rounded
                              : Icons.phone_disabled_rounded,
                        ),
                        _ProtocolRow(
                          label: 'Value',
                          value:
                              appState.phoneStandSensorValue?.toString() ??
                              'Waiting',
                          icon: Icons.sensors_rounded,
                        ),
                        _ProtocolRow(
                          label: 'On threshold',
                          value:
                              appState.phoneStandOnThreshold?.toString() ??
                              'Waiting',
                          icon: Icons.arrow_upward_rounded,
                        ),
                        _ProtocolRow(
                          label: 'Off threshold',
                          value:
                              appState.phoneStandOffThreshold?.toString() ??
                              'Waiting',
                          icon: Icons.arrow_downward_rounded,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          appState.phoneStandMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
                          'Focus behavior',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _ChecklistItem(
                          text:
                              'Start the session after the stand says the phone is on it.',
                        ),
                        const _ChecklistItem(
                          text:
                              'The timer pauses automatically if the phone is lifted.',
                        ),
                        const _ChecklistItem(
                          text:
                              'Put the phone back on the stand to resume the timer.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color _statusColor(SpiralAppState appState) {
  if (appState.isPhoneStandConnected && appState.isPhoneOnStand) {
    return AppPalette.mint;
  }
  if (appState.phoneStandConnectionStatus == PhoneStandConnectionStatus.error) {
    return AppPalette.tangerine;
  }
  if (appState.isPhoneStandConnected) {
    return AppPalette.sun;
  }
  return AppPalette.sky;
}

IconData _statusIcon(SpiralAppState appState) {
  if (appState.isPhoneStandConnected && appState.isPhoneOnStand) {
    return Icons.check_circle_rounded;
  }
  if (appState.isPhoneStandConnected) {
    return Icons.phone_disabled_rounded;
  }
  return Icons.bluetooth_rounded;
}

String _standPrompt(SpiralAppState appState) {
  if (appState.isPhoneStandConnected && appState.isPhoneOnStand) {
    return 'The phone is on the stand. Focus sessions can run.';
  }
  if (appState.isPhoneStandConnected) {
    return 'Place the phone on the stand before starting a focus session.';
  }
  return 'Connect the BLE stand to make focus sessions depend on the phone staying put.';
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
