import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')); // default English

  void changeLocale(Locale newLocale) {
    state = newLocale;
  }

  // Supported languages list (এখানে যতগুলো চাও যোগ করতে পারো)
  static const supportedLocales = [
    Locale('en'), // English
    Locale('bn'), // Bangla
    Locale('ar'), // Arabic
    Locale('ur'), // Urdu
    Locale('tr'), // Turkish
    Locale('id'), // Indonesian
  ];
}
