import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/question.dart';
import 'quiz_state.dart';

final quizViewModelProvider =
    StateNotifierProvider.family<QuizViewModel, QuizState, List<Question>>((
      ref,
      questions,
    ) {
      final viewModel = QuizViewModel(allQuestions: questions);

      ref.onDispose(viewModel.dispose);

      return viewModel;
    });

class QuizViewModel extends StateNotifier<QuizState> {
  QuizViewModel({required List<Question> allQuestions})
    : super(QuizState.initial(allQuestions)) {
    _randomizeQuestions();
  }

  Timer? _timer;
  final Random _random = Random();

  void _randomizeQuestions() {
    // Separate questions by difficulty
    final easyQuestions = state.allQuestions
        .where((q) => q.difficulty.toLowerCase() == 'easy')
        .toList();
    final mediumQuestions = state.allQuestions
        .where((q) => q.difficulty.toLowerCase() == 'medium')
        .toList();
    final hardQuestions = state.allQuestions
        .where((q) => q.difficulty.toLowerCase() == 'hard')
        .toList();

    // Shuffle each list
    easyQuestions.shuffle(_random);
    mediumQuestions.shuffle(_random);
    hardQuestions.shuffle(_random);

    // Select required number of questions (5 easy, 5 medium, 10 hard)
    final selectedEasy = easyQuestions.take(5).toList();
    final selectedMedium = mediumQuestions.take(5).toList();
    final selectedHard = hardQuestions.take(10).toList();

    // Combine and shuffle again to mix difficulties
    final selectedQuestions = [
      ...selectedEasy,
      ...selectedMedium,
      ...selectedHard,
    ]..shuffle(_random);

    state = state.copyWith(questions: selectedQuestions, isRandomizing: false);

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (state.isRandomizing || state.isCompleted) return;

    state = state.copyWith(remainingSeconds: 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        _selectOption(-1);
        _nextQuestion();
        return;
      }

      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  void _selectOption(int index) {
    state = state.copyWith(selectedOptionIndex: index);

    if (index < 0) {
      return;
    }

    final isCorrect = index == state.questions[state.currentIndex].correctIndex;
    if (isCorrect) {
      state = state.copyWith(score: state.score + 1);
    }
  }

  void selectOption(int index) {
    if (state.isCompleted || state.isRandomizing) return;
    if (state.selectedOptionIndex != -1) return;

    _selectOption(index);

    // Give a small delay to show feedback before moving on.
    Future.delayed(const Duration(milliseconds: 550), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (state.isRandomizing) return;

    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.questions.length) {
      _complete();
      return;
    }

    state = state.copyWith(
      currentIndex: nextIndex,
      selectedOptionIndex: -1,
      remainingSeconds: 30,
    );

    _startTimer();
  }

  void _complete() {
    _timer?.cancel();
    state = state.copyWith(isCompleted: true);
  }

  void restart() {
    _timer?.cancel();
    state = QuizState.initial(state.allQuestions);
    _randomizeQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
