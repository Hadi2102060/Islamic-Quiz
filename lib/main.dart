import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/core/providers/locale_provider.dart';
import 'package:quiz_app/core/providers/sound_provider.dart';
import 'package:quiz_app/firebase_options.dart';
import 'package:quiz_app/core/themes/app_theme.dart';
import 'package:quiz_app/l10n/app_localizations.dart';
import 'package:quiz_app/presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: QuizApp()));
}

class QuizApp extends ConsumerWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Islamic Quiz Game',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.theme.copyWith(
        textTheme: GoogleFonts.amiriTextTheme(AppTheme.theme.textTheme),
      ),

      // ✅ Localization part
      locale: locale,
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: AppRouter.router,

      // ✅ Sound initializer keep করা হয়েছে
      builder: (context, child) {
        return SoundInitializer(child: child!);
      },
    );
  }
}

class SoundInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const SoundInitializer({super.key, required this.child});

  @override
  ConsumerState<SoundInitializer> createState() => _SoundInitializerState();
}

class _SoundInitializerState extends ConsumerState<SoundInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    Future.microtask(() async {
      final audio = ref.read(audioServiceProvider);
      await audio.init();

      final isOn = ref.read(soundOnProvider);
      if (isOn) {
        await audio.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
