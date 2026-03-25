import '../entities/quiz_category.dart';
import '../../data/repositories/quiz_repository.dart';

class GetQuizCategoriesUseCase {
  const GetQuizCategoriesUseCase(this.repository);

  final QuizRepository repository;

  Future<List<QuizCategory>> call() => repository.getCategories();
}
