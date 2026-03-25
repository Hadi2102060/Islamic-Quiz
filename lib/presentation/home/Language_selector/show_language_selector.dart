import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/providers/locale_provider.dart';
import 'package:quiz_app/l10n/app_localizations.dart';

/// Shows a language selector bottom sheet safely
void showLanguageSelector(BuildContext context, WidgetRef ref) {
  // 🔹 Read notifier outside modal builder
  final localeNotifier = ref.read(localeProvider.notifier);
  final currentLocale = ref.read(localeProvider);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                AppLocalizations.of(modalContext)!.languages,
                style: Theme.of(modalContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B6B3A),
                ),
              ),
            ),
            ...LocaleNotifier.supportedLocales.map((locale) {
              final isSelected = locale == currentLocale;
              String languageName;

              switch (locale.languageCode) {
                case 'en':
                  languageName = 'English';
                  break;
                case 'bn':
                  languageName = 'বাংলা';
                  break;
                case 'ar':
                  languageName = 'العربية';
                  break;
                case 'ur':
                  languageName = 'اردو';
                  break;
                case 'tr':
                  languageName = 'Türkçe';
                  break;
                case 'id':
                  languageName = 'Bahasa Indonesia';
                  break;
                default:
                  languageName = locale.languageCode.toUpperCase();
              }

              return ListTile(
                leading: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF0B6B3A))
                    : const Icon(Icons.language, color: Colors.grey),
                title: Text(
                  languageName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? const Color(0xFF0B6B3A) : null,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF0B6B3A))
                    : null,
                onTap: () {
                  // 🔹 Change locale globally
                  localeNotifier.changeLocale(locale);

                  // 🔹 Close modal first
                  Navigator.pop(modalContext);

                  // 🔹 Show SnackBar safely after frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (modalContext.mounted) {
                      ScaffoldMessenger.of(modalContext).showSnackBar(
                        SnackBar(
                          content: Text('Language changed to $languageName'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
