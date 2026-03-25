import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/auth/login.dart';
import 'package:quiz_app/presentation/auth/signup.dart';
import 'package:quiz_app/presentation/stats/details_stats.dart';

import '../home/home_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/quiz_screen.dart';
import '../result/result_screen.dart';
import '../results/my_results_screen.dart';
import '../splash/splash_screen.dart';
import '../../domain/entities/quiz_category.dart';
import '../about/about_screen.dart';

class AppRouter {
  AppRouter._();

  static const splash = '/';
  static const home = '/home';
  static const quiz = '/quiz';
  static const result = '/result';
  static const leaderboard = '/leaderboard';
  static const stats = '/stats';
  static const profile = '/profile';
  static const myResults = '/my-results';
  static const about = '/about';
  static const login = '/login';
  static const signup = '/signup';
  static const detailStats = '/stats/detail';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '$quiz/:categoryId',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuizCategory) {
            return QuizScreen(category: extra);
          }
          if (extra is Map && extra['category'] is QuizCategory) {
            final cat = extra['category'] as QuizCategory;
            final restart = extra['restart'] == true;
            return QuizScreen(category: cat, restart: restart);
          }
          return const Scaffold(
            body: Center(child: Text('ক্যাটেগরি ডেটা পাওয়া যায়নি')),
          );
        },
      ),
      GoRoute(
        path: result,
        builder: (context, state) {
          final score =
              int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final total =
              int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;

          final extra = state.extra;
          if (extra is QuizCategory) {
            return ResultScreen(score: score, total: total, category: extra);
          }

          return ResultScreen(score: score, total: total);
        },
      ),
      GoRoute(
        path: leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(path: stats, builder: (context, state) => const StatsScreen()),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: myResults,
        builder: (context, state) => const MyResultsScreen(),
      ),
      GoRoute(path: about, builder: (context, state) => const AboutScreen()),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: signup, builder: (context, state) => const SignUpScreen()),
      GoRoute(
        path: detailStats,
        builder: (context, state) => const DetailedStatsScreen(),
      ),
    ],
  );
}
