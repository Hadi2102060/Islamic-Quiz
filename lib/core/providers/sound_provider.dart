import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/services/audio_services.dart';

// শুধু boolean state — কোনো async logic এখানে নেই
final soundOnProvider = StateProvider<bool>((ref) {
  // optional: app বন্ধ হলে music pause
  ref.onDispose(() {
    AudioService().pause();
  });

  return true; // default: sound ON
});

// AudioService-কে সহজে access করার জন্য
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
