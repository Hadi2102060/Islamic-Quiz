// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizCategoryModelImpl _$$QuizCategoryModelImplFromJson(
  Map<String, dynamic> json,
) => _$QuizCategoryModelImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  questions: (json['questions'] as List<dynamic>)
      .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$QuizCategoryModelImplToJson(
  _$QuizCategoryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'questions': instance.questions,
};
