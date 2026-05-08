import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/data/providers/leaderboard_provider.dart';
import 'package:quiz_app/data/providers/session_user_provider.dart';
import 'package:quiz_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/glass_card.dart';
import '../../domain/entities/quiz_category.dart';
import '../../domain/entities/leaderboard_entry.dart';

import '../router/app_router.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.category,
  });

  final int score;
  final int total;
  final QuizCategory? category;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _scoreSaved = false;
  String? _timeString;
  bool _saveInProgress = false;

  @override
  void initState() {
    super.initState();
    _formatTime();
    _saveScoreToLeaderboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveScoreToLeaderboard();
    });
  }

  void _formatTime() {
    final minutes = 2;
    final seconds = 15;
    _timeString = '${minutes}m ${seconds}s';
  }

  Future<void> _saveScoreToLeaderboard() async {
    if (_scoreSaved || _saveInProgress || widget.category == null) return;

    final userId = await ref.read(sessionUserIdProvider.future);
    if (userId == null) return;

    final firestore = ref.read(firebaseFirestoreProvider);
    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    final userNameRaw = (userData?['name'] as String?)?.trim();
    final userName = (userNameRaw != null && userNameRaw.isNotEmpty)
        ? userNameRaw
        : 'User';
    // Get profile image - can be base64 or URL
    final profileImageBase64 = userData?['profileImageBase64']?.toString();
    final photoUrl =
        userData?['photoUrl']?.toString() ??
        userData?['profileImageUrl']?.toString();

    try {
      _saveInProgress = true;
      await ref
          .read(leaderboardRepositoryProvider)
          .updateUserScore(
            userId: userId,
            userName: userName,
            photoUrl: photoUrl,
            // Pass base64 image
            categoryId: widget.category!.id,
            score: widget.score,
          );

      if (widget.score == widget.total && widget.total > 0) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .add({
              'name': 'Perfect Score',
              'type': 'perfect',
              'progress': 1.0,
              'earnedAt': FieldValue.serverTimestamp(),
              'category': widget.category!.title,
            });
      } else if (widget.score >= (widget.total * 0.8)) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .add({
              'name': 'Top 80%',
              'type': 'top100',
              'progress': widget.score / widget.total,
              'earnedAt': FieldValue.serverTimestamp(),
              'category': widget.category!.title,
            });
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
            'title': widget.category!.title,
            'score': ((widget.score * 100) / widget.total).round(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      final resultDocId = '${userId}_${widget.category!.id}';
      await firestore.collection('results').doc(resultDocId).set({
        'userId': userId,
        'userName': userName,
        'photoUrl': photoUrl,
        'profileImageBase64': profileImageBase64,
        'category': widget.category!.title,
        'categoryId': widget.category!.id,
        'categoryTitle': widget.category!.title,
        'score': widget.score,
        'correctAnswers': widget.score,
        'totalQuestions': widget.total,
        'percentage': widget.total > 0
            ? ((widget.score * 100) / widget.total).round()
            : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _scoreSaved = true;
        _saveInProgress = false;
      });

      ref.invalidate(leaderboardProvider(widget.category!.id));
      ref.invalidate(userRankProvider(widget.category!.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('স্কোর সংরক্ষিত হয়েছে!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _saveInProgress = false;
      print('Error saving score to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase Error: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.total > 0
        ? (widget.score * 100 / widget.total).round()
        : 0;
    final sessionUserId = ref
        .watch(sessionUserIdProvider)
        .maybeWhen(data: (id) => id, orElse: () => null);

    final leaderboardAsync = widget.category != null
        ? ref.watch(leaderboardProvider(widget.category!.id))
        : const AsyncValue.data(<LeaderboardEntry>[]);

    final userRankAsync = widget.category != null
        ? ref.watch(userRankProvider(widget.category!.id))
        : const AsyncValue.data(null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF071B2F), Color(0xFF073E3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.12,
              child: SizedBox(
                width: 300,
                child: Lottie.asset(
                  'assets/lottie_files/Islamic_shape.json',
                  repeat: true,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => AppRouter.router.go(AppRouter.home),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.category != null)
                        Expanded(
                          child: Text(
                            widget.category!.title,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: _AnimatedPercentage(
                      percentage: percentage,
                      label: _getMotivationalMessage(percentage),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'সঠিক উত্তর',
                          value: '${widget.score}/${widget.total}',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF1DE9B6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'সময়',
                          value: _timeString ?? '2m 15s',
                          icon: Icons.access_time,
                          color: const Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.category != null)
                    leaderboardAsync.when(
                      data: (entries) {
                        if (entries.isEmpty) {
                          return _buildEmptyLeaderboard();
                        }
                        return _buildLeaderboardPreview(entries, sessionUserId);
                      },
                      loading: () => _buildLoadingLeaderboard(),
                      error: (error, _) =>
                          _buildErrorLeaderboard(error.toString()),
                    )
                  else
                    _buildNoCategoryLeaderboard(),
                  const Spacer(),
                  if (widget.category != null)
                    userRankAsync.when(
                      data: (rank) {
                        if (rank != null && rank > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: _getRankColor(rank),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'আপনার অবস্থান: #$rank',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (rank <= 3)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRankColor(
                                            rank,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _getRankColor(
                                              rank,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _getRankTitle(rank),
                                          style: TextStyle(
                                            color: _getRankColor(rank),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  Row(
                    children: [
                      Expanded(child: _buildPlayAgainButton()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShareButton(
                          score: widget.score,
                          total: widget.total,
                          category: widget.category,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(int percentage) {
    if (percentage >= 90) return 'মাশাআল্লাহ! অসাধারণ!';
    if (percentage >= 75) return 'চমৎকার!';
    if (percentage >= 60) return 'ভালো হয়েছে!';
    if (percentage >= 40) return 'আরও চেষ্টা করুন!';
    return 'পরের বার নিশ্চয়ই ভালো হবে!';
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  String _getRankTitle(int rank) {
    switch (rank) {
      case 1:
        return 'চ্যাম্পিয়ন';
      case 2:
        return 'রানার আপ';
      case 3:
        return 'সেকেন্ড রানার আপ';
      default:
        return '';
    }
  }

  Widget _buildLeaderboardPreview(
    List<LeaderboardEntry> entries,
    String? currentUserId,
  ) {
    final topEntries = entries.take(3).toList();

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'লিডারবোর্ড',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              InkWell(
                onTap: () {
                  AppRouter.router.push(AppRouter.leaderboard);
                },
                child: Row(
                  children: [
                    Text(
                      'সব দেখুন',
                      style: GoogleFonts.inter(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.amber,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              if (index < topEntries.length) {
                final entry = topEntries[index];
                final isCurrentUser = entry.userId == currentUserId;
                return _buildTopPlayer(
                  rank: index + 1,
                  entry: entry,
                  isCurrentUser: isCurrentUser,
                );
              } else {
                return _buildEmptyTopPlayer(index + 1);
              }
            }),
          ),
          if (entries.length > 3) ...[
            const SizedBox(height: 12),
            ...List.generate(entries.skip(3).take(2).length, (index) {
              final entry = entries.skip(3).toList()[index];
              final globalIndex = index + 4;
              final isCurrentUser = entry.userId == currentUserId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: Center(
                        child: Text(
                          '#$globalIndex',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUserAvatar(entry, radius: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.amber : Colors.white,
                          fontSize: 12,
                          fontWeight: isCurrentUser
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.categoryScores[widget.category!.id] ?? 0} pts',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTopPlayer({
    required int rank,
    required LeaderboardEntry entry,
    required bool isCurrentUser,
  }) {
    final rankColors = [Colors.amber, Colors.grey, Colors.brown];
    final rankSize = rank == 1 ? 60.0 : 50.0;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: rankSize,
              height: rankSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColors[rank - 1].withOpacity(0.2),
                border: Border.all(
                  color: rankColors[rank - 1].withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: _buildUserAvatar(entry, radius: rank == 1 ? 24 : 20),
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entry.userName.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrentUser ? Colors.amber : Colors.white,
            fontSize: 11,
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${entry.categoryScores[widget.category!.id] ?? 0} pts',
          style: TextStyle(
            color: rankColors[rank - 1],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(LeaderboardEntry entry, {required double radius}) {
    // First priority: Use profileImageBase64 if available
    if (entry.profileImageBase64 != null &&
        entry.profileImageBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white12,
          backgroundImage: MemoryImage(base64Decode(entry.profileImageBase64!)),
          onBackgroundImageError: (_, __) =>
              _buildFallbackAvatar(entry, radius),
        );
      } catch (e) {
        return _buildFallbackAvatar(entry, radius);
      }
    }

    // Second priority: Use photoUrl (network image)
    if (entry.photoUrl != null && entry.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        backgroundImage: NetworkImage(entry.photoUrl!),
        onBackgroundImageError: (_, __) => _buildFallbackAvatar(entry, radius),
      );
    }

    // Fallback: Show initials
    return _buildFallbackAvatar(entry, radius);
  }

  Widget _buildFallbackAvatar(LeaderboardEntry entry, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade800,
      child: Text(
        entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyTopPlayer(int rank) {
    final rankColors = [Colors.amber, Colors.grey, Colors.brown];
    final rankSize = rank == 1 ? 60.0 : 50.0;

    return Column(
      children: [
        Container(
          width: rankSize,
          height: rankSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rankColors[rank - 1].withOpacity(0.1),
            border: Border.all(
              color: rankColors[rank - 1].withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColors[rank - 1].withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '???',
          style: TextStyle(
            color: rankColors[rank - 1].withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLeaderboard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'এই ক্যাটাগরিতে এখনও কোনো ফলাফল নেই',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'প্রথম খেলোয়াড় হও!',
            style: GoogleFonts.inter(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingLeaderboard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
      ),
    );
  }

  Widget _buildErrorLeaderboard(String error) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 30),
            const SizedBox(height: 8),
            Text(
              'লিডারবোর্ড লোড করতে সমস্যা',
              style: GoogleFonts.inter(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCategoryLeaderboard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events,
              size: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'ক্যাটাগরি নির্বাচন করে লিডারবোর্ড দেখুন',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayAgainButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFF1DE9B6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (widget.category != null) {
              AppRouter.router.go(
                '${AppRouter.quiz}/${widget.category!.id}',
                extra: {'category': widget.category, 'restart': true},
              );
            } else {
              AppRouter.router.go(AppRouter.home);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'আবার খেলুন',
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPercentage extends StatefulWidget {
  const _AnimatedPercentage({required this.percentage, required this.label});

  final int percentage;
  final String label;

  @override
  State<_AnimatedPercentage> createState() => _AnimatedPercentageState();
}

class _AnimatedPercentageState extends State<_AnimatedPercentage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final v =
                  Curves.easeOut.transform(_ctrl.value) *
                  (widget.percentage / 100);
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B6B3A), Color(0xFF1B9C5A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 10,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(Colors.amber.shade200),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(v * 100).round()}%',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hover ? widget.color.withOpacity(0.12) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color, widget.color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.score, required this.total, this.category});

  final int score;
  final int total;
  final QuizCategory? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        color: Colors.white12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final categoryText = category != null ? '${category!.title} ' : '';
            final shareText =
                'আমি The Quran Quiz অ্যাপে ${categoryText}ক্যাটাগরিতে $score/$total পেয়েছি! আপনি কি পারবেন?\n\nডাউনলোড লিংক: https://example.com/app';

            await Clipboard.setData(ClipboardData(text: shareText));

            if (context.mounted) {
              Share.share(
                'Peace be upon you, I just played "The Quran Quiz". '
                'Check it out and join me: https://example.com/app_link',
                subject: 'Join me in The Quran Quiz!',
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'শেয়ার করুন',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
