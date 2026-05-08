import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final String? profileImageBase64; // Added this field for base64 images
  final int totalScore;
  final int quizzesPlayed;
  final int badges;
  final DateTime lastPlayed;
  final Map<String, int> categoryScores; // categoryId -> score

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
    this.profileImageBase64, // Added to constructor
    required this.totalScore,
    required this.quizzesPlayed,
    required this.badges,
    required this.lastPlayed,
    required this.categoryScores,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, String id) {
    return LeaderboardEntry(
      userId: id,
      userName: map['userName'] ?? 'Unknown User',
      photoUrl: map['photoUrl'],
      profileImageBase64: map['profileImageBase64'], // Added this line
      totalScore: map['totalScore'] ?? 0,
      quizzesPlayed: map['quizzesPlayed'] ?? 0,
      badges: map['badges'] ?? 0,
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
    );
  }

  // Alternative factory for Firestore documents
  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry(
      userId: doc.id,
      userName: data['userName'] ?? 'Unknown User',
      photoUrl: data['photoUrl'],
      profileImageBase64: data['profileImageBase64'], // Added this line
      totalScore: data['totalScore'] ?? 0,
      quizzesPlayed: data['quizzesPlayed'] ?? 0,
      badges: data['badges'] ?? 0,
      lastPlayed:
          (data['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryScores: Map<String, int>.from(data['categoryScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'photoUrl': photoUrl,
      'profileImageBase64': profileImageBase64, // Added this line
      'totalScore': totalScore,
      'quizzesPlayed': quizzesPlayed,
      'badges': badges,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
      'categoryScores': categoryScores,
    };
  }

  // Copy with method for easy updates
  LeaderboardEntry copyWith({
    String? userId,
    String? userName,
    String? photoUrl,
    String? profileImageBase64,
    int? totalScore,
    int? quizzesPlayed,
    int? badges,
    DateTime? lastPlayed,
    Map<String, int>? categoryScores,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      photoUrl: photoUrl ?? this.photoUrl,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      totalScore: totalScore ?? this.totalScore,
      quizzesPlayed: quizzesPlayed ?? this.quizzesPlayed,
      badges: badges ?? this.badges,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      categoryScores: categoryScores ?? this.categoryScores,
    );
  }

  // Get score for a specific category
  int getCategoryScore(String categoryId) {
    return categoryScores[categoryId] ?? 0;
  }

  // Update score for a specific category
  LeaderboardEntry updateCategoryScore(String categoryId, int newScore) {
    final updatedScores = Map<String, int>.from(categoryScores);
    final currentScore = updatedScores[categoryId] ?? 0;

    if (newScore > currentScore) {
      updatedScores[categoryId] = newScore;
      final newTotalScore = updatedScores.values.fold(
        0,
        (sum, score) => sum + score,
      );

      return copyWith(
        categoryScores: updatedScores,
        totalScore: newTotalScore,
        lastPlayed: DateTime.now(),
      );
    }
    return this;
  }

  @override
  String toString() {
    return 'LeaderboardEntry(userId: $userId, userName: $userName, totalScore: $totalScore, quizzesPlayed: $quizzesPlayed, badges: $badges)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.userName == userName &&
        other.photoUrl == photoUrl &&
        other.profileImageBase64 == profileImageBase64 &&
        other.totalScore == totalScore &&
        other.quizzesPlayed == quizzesPlayed &&
        other.badges == badges &&
        other.lastPlayed == lastPlayed &&
        other.categoryScores == categoryScores;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      userName,
      photoUrl,
      profileImageBase64,
      totalScore,
      quizzesPlayed,
      badges,
      lastPlayed,
      categoryScores,
    );
  }
}
