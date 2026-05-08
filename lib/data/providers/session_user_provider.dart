import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Returns the current app "userId" based on our phone-login session.
///
/// Important: this app's OTP flow currently does NOT sign-in to `FirebaseAuth`.
/// So UI/data layers must use `SharedPreferences` to identify the user for
/// Firestore reads/writes.
final sessionUserIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  final savedUserId = prefs.getString('userId')?.trim();
  if (savedUserId != null && savedUserId.isNotEmpty) {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }
    return savedUserId;
  }

  final phone = prefs.getString('userPhone')?.trim() ?? '';
  if (phone.isEmpty) return null;

  // Firebase docId/security rules assume phone digits only.
  final derivedUserId = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (derivedUserId.isNotEmpty) {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }
    return derivedUserId;
  }

  return null;
});
