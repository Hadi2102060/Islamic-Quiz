import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/domain/entities/leaderboard_entry.dart';
import 'package:quiz_app/services/firebase_service.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.read(firebaseFirestoreProvider));
});

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((
      ref,
      categoryId,
    ) async {
      final repository = ref.read(leaderboardRepositoryProvider);
      return await repository.getLeaderboardByCategory(categoryId);
    });

final userRankProvider = FutureProvider.family<int?, String>((
  ref,
  categoryId,
) async {
  final currentUser = ref.read(authStateProvider).value;
  if (currentUser == null) return null;

  final repository = ref.read(leaderboardRepositoryProvider);
  return await repository.getUserRank(categoryId, currentUser.uid);
});

class LeaderboardRepository {
  final FirebaseFirestore _firestore;

  LeaderboardRepository(this._firestore);

  Future<List<LeaderboardEntry>> getLeaderboardByCategory(
    String categoryId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('categoryScores.$categoryId', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data(), doc.id))
          .where((entry) => entry.categoryScores.containsKey(categoryId))
          .toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<int?> getUserRank(String categoryId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('categoryScores.$categoryId', descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data(), doc.id))
          .where((entry) => entry.categoryScores.containsKey(categoryId))
          .toList();

      final index = entries.indexWhere((entry) => entry.userId == userId);
      return index != -1 ? index + 1 : null;
    } catch (e) {
      print('Error getting user rank: $e');
      return null;
    }
  }

  Future<void> updateUserScore({
    required String userId,
    required String userName,
    String? photoUrl,
    required String categoryId,
    required int score,
  }) async {
    try {
      final userRef = _firestore.collection('leaderboard').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (snapshot.exists) {
          // Update existing user
          final data = snapshot.data()!;
          final categoryScores = Map<String, int>.from(
            data['categoryScores'] ?? {},
          );
          final currentScore = categoryScores[categoryId] ?? 0;

          // Only update if new score is higher
          if (score > currentScore) {
            categoryScores[categoryId] = score;

            // Recalculate total score
            final totalScore = categoryScores.values.fold(
              0,
              (sum, s) => sum + s,
            );

            transaction.update(userRef, {
              'userName': userName,
              'photoUrl': photoUrl,
              'totalScore': totalScore,
              'quizzesPlayed': FieldValue.increment(1),
              'badges': _calculateBadges(totalScore),
              'lastPlayed': FieldValue.serverTimestamp(),
              'categoryScores': categoryScores,
            });
          } else {
            // Just update play count and last played
            transaction.update(userRef, {
              'quizzesPlayed': FieldValue.increment(1),
              'lastPlayed': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Create new user
          final categoryScores = {categoryId: score};

          transaction.set(userRef, {
            'userName': userName,
            'photoUrl': photoUrl,
            'totalScore': score,
            'quizzesPlayed': 1,
            'badges': _calculateBadges(score),
            'lastPlayed': FieldValue.serverTimestamp(),
            'categoryScores': categoryScores,
          });
        }
      });
    } catch (e) {
      print('Error updating user score: $e');
    }
  }

  int _calculateBadges(int totalScore) {
    if (totalScore >= 1000) return 5;
    if (totalScore >= 750) return 4;
    if (totalScore >= 500) return 3;
    if (totalScore >= 250) return 2;
    if (totalScore >= 100) return 1;
    return 0;
  }
}
