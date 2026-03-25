import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/quiz_repository.dart';
import '../sources/local/quiz_local_data_source.dart';
import '../../domain/entities/quiz_category.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/get_quiz_categories_usecase.dart';

// PART 1: Existing providers (keeping your original structure)

final quizLocalDataSourceProvider = Provider<QuizLocalDataSource>((ref) {
  return const QuizLocalDataSourceImpl();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(
    localDataSource: ref.read(quizLocalDataSourceProvider),
  );
});

final getQuizCategoriesUseCaseProvider = Provider<GetQuizCategoriesUseCase>((
  ref,
) {
  return GetQuizCategoriesUseCase(ref.read(quizRepositoryProvider));
});

/// Provides a list of available quiz categories.
final quizCategoriesProvider = FutureProvider.autoDispose<List<QuizCategory>>((
  ref,
) {
  return ref.read(getQuizCategoriesUseCaseProvider)();
});

// PART 2: New providers for category management and question filtering

/// Provider for selected category
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Provider for selected category object
final selectedCategoryProvider = Provider<QuizCategory?>((ref) {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  if (categoryId == null) return null;

  final categoriesAsync = ref.watch(quizCategoriesProvider);
  return categoriesAsync.when(
    data: (categories) => categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('Category not found'),
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for category title
final selectedCategoryTitleProvider = Provider<String?>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return category?.title;
});

/// Provider for filtering questions by difficulty
final questionFilterProvider = StateProvider<QuestionFilter>((ref) {
  return const QuestionFilter();
});

/// Provider for getting filtered questions from selected category
final filteredQuestionsProvider = Provider<List<Question>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final filter = ref.watch(questionFilterProvider);

  if (category == null) return [];

  var questions = category.questions;

  // Filter by difficulty if specified
  if (filter.difficulty != null) {
    questions = questions
        .where(
          (q) => q.difficulty.toLowerCase() == filter.difficulty!.toLowerCase(),
        )
        .toList();
  }

  // Apply search if needed
  if (filter.searchQuery.isNotEmpty) {
    questions = questions
        .where(
          (q) => q.question.toLowerCase().contains(
            filter.searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  return questions;
});

/// Provider for getting questions by difficulty counts
final questionsByDifficultyProvider = Provider<Map<String, int>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return {};

  final questions = category.questions;

  return {
    'easy': questions.where((q) => q.difficulty.toLowerCase() == 'easy').length,
    'medium': questions
        .where((q) => q.difficulty.toLowerCase() == 'medium')
        .length,
    'hard': questions.where((q) => q.difficulty.toLowerCase() == 'hard').length,
  };
});

/// Provider for getting random questions with specific difficulty distribution
final randomQuestionsProvider =
    Provider.family<List<Question>, RandomQuestionsConfig>((ref, config) {
      final category = ref.watch(selectedCategoryProvider);
      if (category == null) return [];

      final allQuestions = category.questions;

      // Separate questions by difficulty
      final easyQuestions =
          allQuestions
              .where((q) => q.difficulty.toLowerCase() == 'easy')
              .toList()
            ..shuffle();
      final mediumQuestions =
          allQuestions
              .where((q) => q.difficulty.toLowerCase() == 'medium')
              .toList()
            ..shuffle();
      final hardQuestions =
          allQuestions
              .where((q) => q.difficulty.toLowerCase() == 'hard')
              .toList()
            ..shuffle();

      // Select requested number of questions
      final selectedEasy = easyQuestions.take(config.easyCount).toList();
      final selectedMedium = mediumQuestions.take(config.mediumCount).toList();
      final selectedHard = hardQuestions.take(config.hardCount).toList();

      // Combine and shuffle
      return [...selectedEasy, ...selectedMedium, ...selectedHard]..shuffle();
    });

/// Provider for category statistics
final categoryStatsProvider = FutureProvider.family<CategoryStats, String>((
  ref,
  categoryId,
) async {
  // This would typically come from Firebase/Firestore
  // For now, returning mock data
  return CategoryStats(
    totalPlayers: 1250,
    averageScore: 75,
    topScore: 100,
    quizzesPlayed: 5000,
  );
});

/// Provider for checking if category has enough questions
final categoryAvailabilityProvider = Provider.family<bool, String>((
  ref,
  categoryId,
) {
  final categoriesAsync = ref.watch(quizCategoriesProvider);

  return categoriesAsync.when(
    data: (categories) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      );

      // Check if category has at least 20 questions
      return category.questions.length >= 20;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for recommended categories based on user performance
final recommendedCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) {
  // This would typically come from Firebase/Firestore based on user history
  // For now, returning first 3 categories
  final categoriesAsync = ref.watch(quizCategoriesProvider);

  return categoriesAsync.when(
    data: (categories) => categories.take(3).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// PART 3: Models and Config classes

/// Filter for questions
class QuestionFilter {
  final String? difficulty;
  final String searchQuery;

  const QuestionFilter({this.difficulty, this.searchQuery = ''});

  QuestionFilter copyWith({String? difficulty, String? searchQuery}) {
    return QuestionFilter(
      difficulty: difficulty ?? this.difficulty,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Configuration for random questions selection
class RandomQuestionsConfig {
  final int easyCount;
  final int mediumCount;
  final int hardCount;

  const RandomQuestionsConfig({
    required this.easyCount,
    required this.mediumCount,
    required this.hardCount,
  });

  // Default config for 20 questions (5 easy, 5 medium, 10 hard)
  factory RandomQuestionsConfig.default_20() {
    return const RandomQuestionsConfig(
      easyCount: 5,
      mediumCount: 5,
      hardCount: 10,
    );
  }

  // Config for 10 questions (3 easy, 3 medium, 4 hard)
  factory RandomQuestionsConfig.quick_10() {
    return const RandomQuestionsConfig(
      easyCount: 3,
      mediumCount: 3,
      hardCount: 4,
    );
  }
}

/// Category statistics
class CategoryStats {
  final int totalPlayers;
  final double averageScore;
  final int topScore;
  final int quizzesPlayed;

  CategoryStats({
    required this.totalPlayers,
    required this.averageScore,
    required this.topScore,
    required this.quizzesPlayed,
  });
}

// PART 4: Async Notifier for category management (Alternative to FutureProvider)

class QuizCategoriesController extends AsyncNotifier<List<QuizCategory>> {
  @override
  Future<List<QuizCategory>> build() async {
    return _loadCategories();
  }

  Future<List<QuizCategory>> _loadCategories() async {
    try {
      final useCase = ref.read(getQuizCategoriesUseCaseProvider);
      return await useCase();
    } catch (e, stack) {
      throw Error.throwWithStackTrace(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadCategories);
  }
}

final quizCategoriesControllerProvider =
    AsyncNotifierProvider<QuizCategoriesController, List<QuizCategory>>(() {
      return QuizCategoriesController();
    });

// PART 5: Helper providers for UI

/// Provider for category icon based on category id
final categoryIconProvider = Provider.family<IconData, String>((
  ref,
  categoryId,
) {
  switch (categoryId) {
    case 'islam':
      return Icons.mosque;
    case 'quran':
      return Icons.menu_book;
    case 'general':
      return Icons.lightbulb;
    case 'surahs':
      return Icons.format_list_numbered;
    case 'verses':
      return Icons.auto_stories;
    case 'prophets':
      return Icons.people;
    case 'seerah':
      return Icons.timeline;
    case 'all':
      return Icons.category;
    default:
      return Icons.help;
  }
});

/// Provider for category color based on category id
final categoryColorProvider = Provider.family<Color, String>((ref, categoryId) {
  switch (categoryId) {
    case 'islam':
      return Colors.green;
    case 'quran':
      return Colors.blue;
    case 'general':
      return Colors.orange;
    case 'surahs':
      return Colors.purple;
    case 'verses':
      return Colors.teal;
    case 'prophets':
      return Colors.amber;
    case 'seerah':
      return Colors.red;
    case 'all':
      return Colors.pink;
    default:
      return Colors.grey;
  }
});

/// Provider for category progress (would be connected to user's history)
final categoryProgressProvider = Provider.family<double, String>((
  ref,
  categoryId,
) {
  // This would typically come from Firebase/Firestore
  // For now, returning random progress
  return 0.0;
});

/// Provider for checking if category is unlocked
final categoryUnlockedProvider = Provider.family<bool, String>((
  ref,
  categoryId,
) {
  // This would typically come from Firebase/Firestore
  // For now, all categories are unlocked
  return true;
});
