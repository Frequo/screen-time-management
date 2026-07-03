import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:spiral_notebook/app_state.dart';

class PhoneStandBleController extends ChangeNotifier {
  PhoneStandBleController({required SpiralAppState appState})
    : _appState = appState;

  static const String deviceName = 'FSR Phone';
  static const String serviceName = 'Nordic UART BLE service';
  static final Guid uartServiceUuid = Guid(
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
  );
  static final Guid uartRxCharacteristicUuid = Guid(
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  );
  static final Guid uartTxCharacteristicUuid = Guid(
    '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
  );

  final SpiralAppState _appState;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _messageSubscription;
  bool _busy = false;
  String _incomingBuffer = '';

  bool get isBusy => _busy;

  bool get canSendCommand =>
      _appState.isPhoneStandConnected && _rxCharacteristic != null;

  Future<void> connect() async {
    if (_busy) {
      return;
    }

    _setBusy(true);
    try {
      final bool supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        _appState.updatePhoneStandConnectionStatus(
          PhoneStandConnectionStatus.unsupported,
          message: 'Bluetooth LE is not available on this device.',
        );
        return;
      }

      _appState.updatePhoneStandConnectionStatus(
        PhoneStandConnectionStatus.scanning,
        message: 'Looking for $deviceName...',
      );

      final BluetoothAdapterState adapterState = await FlutterBluePlus
          .adapterState
          .where((BluetoothAdapterState state) {
            return state == BluetoothAdapterState.on ||
                state == BluetoothAdapterState.unauthorized ||
                state == BluetoothAdapterState.unavailable;
          })
          .first
          .timeout(const Duration(seconds: 15));

      if (adapterState != BluetoothAdapterState.on) {
        _appState.updatePhoneStandConnectionStatus(
          PhoneStandConnectionStatus.error,
          message: 'Turn on Bluetooth and allow Bluetooth access.',
        );
        return;
      }

      final ScanResult scanResult = await _findStand();
      await _connectToDevice(scanResult.device);
    } catch (error) {
      _appState.updatePhoneStandConnectionStatus(
        PhoneStandConnectionStatus.error,
        message: 'Could not connect to $deviceName: $error',
      );
      await _cleanupConnection(disconnectDevice: false);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> disconnect() async {
    _setBusy(true);
    try {
      await _cleanupConnection(disconnectDevice: true);
      _appState.updatePhoneStandConnectionStatus(
        PhoneStandConnectionStatus.disconnected,
        message: '$deviceName disconnected.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> requestStatus() => _sendCommand('status');

  Future<void> calibrate() => _sendCommand('calibrate');

  Future<ScanResult> _findStand() async {
    final Completer<ScanResult> completer = Completer<ScanResult>();

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((
      List<ScanResult> results,
    ) {
      for (final ScanResult result in results) {
        if (_matchesStand(result) && !completer.isCompleted) {
          completer.complete(result);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(
      withNames: const <String>[deviceName],
      timeout: const Duration(seconds: 10),
    );

    try {
      return await completer.future.timeout(const Duration(seconds: 11));
    } finally {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  bool _matchesStand(ScanResult result) {
    return result.advertisementData.advName == deviceName ||
        result.device.advName == deviceName ||
        result.device.platformName == deviceName;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _appState.updatePhoneStandConnectionStatus(
      PhoneStandConnectionStatus.connecting,
      message: 'Connecting to $deviceName...',
    );

    await _cleanupConnection(disconnectDevice: false);
    _device = device;
    _connectionSubscription = device.connectionState.listen((
      BluetoothConnectionState state,
    ) {
      if (state == BluetoothConnectionState.disconnected) {
        _rxCharacteristic = null;
        _txCharacteristic = null;
        _appState.updatePhoneStandConnectionStatus(
          PhoneStandConnectionStatus.disconnected,
          message: '$deviceName disconnected.',
        );
      }
    });

    await device
        .connect(license: License.nonprofit)
        .timeout(const Duration(seconds: 15));
    final List<BluetoothService> services = await device.discoverServices();
    final BluetoothService uartService = services.firstWhere(
      (BluetoothService service) => service.uuid == uartServiceUuid,
      orElse: () => throw StateError('$serviceName was not found.'),
    );

    _rxCharacteristic = uartService.characteristics.firstWhere(
      (BluetoothCharacteristic characteristic) =>
          characteristic.uuid == uartRxCharacteristicUuid,
      orElse: () =>
          throw StateError('UART write characteristic was not found.'),
    );
    _txCharacteristic = uartService.characteristics.firstWhere(
      (BluetoothCharacteristic characteristic) =>
          characteristic.uuid == uartTxCharacteristicUuid,
      orElse: () =>
          throw StateError('UART notification characteristic was not found.'),
    );

    _messageSubscription = _txCharacteristic!.onValueReceived.listen(
      _handleMessageBytes,
    );
    await _txCharacteristic!.setNotifyValue(true);

    _appState.updatePhoneStandConnectionStatus(
      PhoneStandConnectionStatus.connected,
      message: '$deviceName connected. Waiting for sensor status...',
    );
    await requestStatus();
  }

  Future<void> _sendCommand(String command) async {
    final BluetoothCharacteristic? characteristic = _rxCharacteristic;
    if (characteristic == null) {
      _appState.updatePhoneStandConnectionStatus(
        PhoneStandConnectionStatus.error,
        message: 'Connect the stand before sending $command.',
      );
      return;
    }

    final bool withoutResponse =
        characteristic.properties.writeWithoutResponse &&
        !characteristic.properties.write;
    await characteristic.write(<int>[
      ...utf8.encode(command),
      10,
    ], withoutResponse: withoutResponse);
  }

  void _handleMessageBytes(List<int> bytes) {
    _incomingBuffer += utf8.decode(bytes, allowMalformed: true);
    _incomingBuffer = _incomingBuffer.replaceAll('\r', '\n');

    while (_incomingBuffer.contains('\n')) {
      final int lineEnd = _incomingBuffer.indexOf('\n');
      final String line = _incomingBuffer.substring(0, lineEnd).trim();
      _incomingBuffer = _incomingBuffer.substring(lineEnd + 1);
      _appState.applyPhoneStandMessage(line);
    }
  }

  Future<void> _cleanupConnection({required bool disconnectDevice}) async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    final BluetoothCharacteristic? txCharacteristic = _txCharacteristic;
    if (txCharacteristic != null && txCharacteristic.isNotifying) {
      try {
        await txCharacteristic.setNotifyValue(false);
      } on Exception {
        // The device may already be gone.
      }
    }

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final BluetoothDevice? device = _device;
    if (disconnectDevice && device != null) {
      try {
        await device.disconnect();
      } on Exception {
        // The native stack can throw when a disconnect races with link loss.
      }
    }

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _incomingBuffer = '';
  }

  void _setBusy(bool value) {
    if (_busy == value) {
      return;
    }
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_cleanupConnection(disconnectDevice: true));
    super.dispose();
  }
}
