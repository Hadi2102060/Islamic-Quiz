import '../../domain/entities/quiz_category.dart';
import '../sources/local/quiz_local_data_source.dart';

abstract class QuizRepository {
  Future<List<QuizCategory>> getCategories();
}

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl({required this.localDataSource});

  final QuizLocalDataSource localDataSource;

  @override
  Future<List<QuizCategory>> getCategories() {
    return localDataSource.loadCategories();
  }
}
