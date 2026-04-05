import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:spiral_notebook/app_state.dart';

class FocusAmbientAudioController {
  FocusAmbientAudioController({required SpiralAppState appState})
    : _appState = appState {
    _appState.addListener(_handleStateChanged);
    unawaited(_initialize());
  }

  static const String _assetPath = 'quietphase-calm-ambient-491577.mp3';
  static const double _ambientVolume = 0.14;

  final SpiralAppState _appState;
  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;
  bool _isDisposed = false;

  Future<void> _initialize() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_ambientVolume);
    await _player.setSource(AssetSource(_assetPath));
    _isInitialized = true;
    await _syncPlayback();
  }

  void _handleStateChanged() {
    unawaited(_syncPlayback());
  }

  Future<void> _syncPlayback() async {
    if (!_isInitialized || _isDisposed) {
      return;
    }

    final bool shouldPlay =
        _appState.isFocusActive &&
        !_appState.isFocusPaused &&
        _appState.soundEnabled &&
        _appState.ambientSoundsEnabled;

    if (shouldPlay) {
      await _player.resume();
      return;
    }

    await _player.pause();
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _appState.removeListener(_handleStateChanged);
    await _player.dispose();
  }
}
