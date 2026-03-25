import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/services/audio_services.dart';

final soundNotifierProvider = StateNotifierProvider<SoundNotifier, bool>((ref) {
  return SoundNotifier();
});

class SoundNotifier extends StateNotifier<bool> {
  SoundNotifier() : super(true) {
    // App start হওয়ার সাথে সাথে music চালু
    _initializeMusic();
  }

  final _audio = AudioService();

  Future<void> _initializeMusic() async {
    await _audio.init();
    if (state) {
      await _audio.play();
    }
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue; // UI instantly update হয়

    if (newValue) {
      await _audio.play();
    } else {
      await _audio.pause();
    }
  }

  // Optional: app close হলে music stop
  @override
  void dispose() {
    _audio.pause();
    super.dispose();
  }
}
