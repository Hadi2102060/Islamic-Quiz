import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _player.setAsset('assets/audio/islamic_song.mp3');
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(0.4);
      _initialized = true;
      debugPrint("✅ Audio initialized");
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  Future<void> play() async {
    if (!_initialized) await init();
    await _player.play();
    debugPrint("▶️ Music PLAYING");
  }

  Future<void> pause() async {
    if (!_initialized) return;
    await _player.pause();
    debugPrint("⏸️ Music PAUSED");
  }
}
