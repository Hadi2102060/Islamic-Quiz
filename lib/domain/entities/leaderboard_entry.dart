import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? photoUrl;
  final int totalScore;
  final int quizzesPlayed;
  final int badges;
  final DateTime lastPlayed;
  final Map<String, int> categoryScores; // categoryId -> score

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.photoUrl,
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
      totalScore: map['totalScore'] ?? 0,
      quizzesPlayed: map['quizzesPlayed'] ?? 0,
      badges: map['badges'] ?? 0,
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'photoUrl': photoUrl,
      'totalScore': totalScore,
      'quizzesPlayed': quizzesPlayed,
      'badges': badges,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
      'categoryScores': categoryScores,
    };
  }
}
