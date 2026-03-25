import 'question.dart';

class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final List<Question> questions;
}
