import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/question.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String id,
    required String question,
    required List<String> options,
    required int correctIndex,
    required String difficulty, // Add difficulty field
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}

extension QuestionModelX on QuestionModel {
  Question toEntity() => Question(
    id: id,
    question: question,
    options: options,
    correctIndex: correctIndex,
    difficulty: difficulty,
  );
}
