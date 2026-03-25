import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/question.dart';

part 'quiz_state.freezed.dart';

@freezed
class QuizState with _$QuizState {
  const factory QuizState({
    required List<Question> allQuestions, // All questions from category
    required List<Question> questions, // Selected 20 questions
    required int currentIndex,
    required int score,
    required int selectedOptionIndex,
    required bool isCompleted,
    required int remainingSeconds,
    required bool isRandomizing, // Loading state while randomizing
  }) = _QuizState;

  factory QuizState.initial(List<Question> allQuestions) => QuizState(
    allQuestions: allQuestions,
    questions: [],
    currentIndex: 0,
    score: 0,
    selectedOptionIndex: -1,
    isCompleted: false,
    remainingSeconds: 30,
    isRandomizing: true, // Start with loading state
  );
}
