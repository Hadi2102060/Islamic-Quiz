import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/quiz_category.dart';
import 'question_model.dart';

part 'quiz_category_model.freezed.dart';
part 'quiz_category_model.g.dart';

@freezed
class QuizCategoryModel with _$QuizCategoryModel {
  const factory QuizCategoryModel({
    required String id,
    required String title,
    required String description,
    required List<QuestionModel> questions,
  }) = _QuizCategoryModel;

  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$QuizCategoryModelFromJson(json);
}

extension QuizCategoryModelX on QuizCategoryModel {
  QuizCategory toEntity() => QuizCategory(
    id: id,
    title: title,
    description: description,
    questions: questions.map((q) => q.toEntity()).toList(),
  );
}
