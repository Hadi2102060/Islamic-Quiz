import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/entities/quiz_category.dart';
import '../../models/quiz_category_model.dart';

abstract class QuizLocalDataSource {
  Future<List<QuizCategory>> loadCategories();
}

class QuizLocalDataSourceImpl implements QuizLocalDataSource {
  const QuizLocalDataSourceImpl();

  @override
  Future<List<QuizCategory>> loadCategories() async {
    final jsonString = await rootBundle.loadString(
      'assets/quiz/all_questions.json',
    );
    final Map<String, dynamic> jsonMap =
        json.decode(jsonString) as Map<String, dynamic>;

    final categoriesJson = (jsonMap['categories'] as List<dynamic>?) ?? [];

    return categoriesJson
        .map(
          (e) =>
              QuizCategoryModel.fromJson(e as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }
}
