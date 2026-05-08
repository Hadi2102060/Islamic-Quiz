import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/data/providers/session_user_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DetailedStatsScreen extends ConsumerWidget {
  const DetailedStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(sessionUserIdProvider);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        AppRouter.router.go(AppRouter.stats);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 4),
              curve: Curves.easeInOut,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071B2F),
                    Color(0xFF073E3A),
                    Color(0xFF0A4D4A),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -30,
              child: Opacity(
                opacity: 0.14,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Lottie.asset(
                    'assets/lottie_files/Islamic_shape.json',
                    repeat: true,
                  ),
                ),
              ),
            ),
            ...List.generate(
              5,
              (i) => Positioned(
                left: (i * 65.0) % 380,
                top: (i * 95.0) % 720,
                child:
                    Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 900.ms, delay: (i * 150).ms)
                        .shimmer(duration: 2500.ms, color: Colors.white30)
                        .then()
                        .moveY(
                          begin: 0,
                          end: 22,
                          duration: 3800.ms,
                          curve: Curves.easeInOut,
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true)),
              ),
            ),
            SafeArea(
              child: userIdAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ত্রুটি: $err',
                      style: GoogleFonts.inter(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (userId) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
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
                                onTap: () =>
                                    AppRouter.router.go(AppRouter.stats),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ).animate().scale(
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child:
                                  Text(
                                        'Detailed Analytics',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                      .animate()
                                      .fadeIn(duration: 500.ms)
                                      .slideX(begin: -0.25, end: 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        if (userId == null)
                          Center(
                            child: Text(
                              'Sign in to see your detailed analytics',
                              style: GoogleFonts.inter(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('results')
                                .where('userId', isEqualTo: userId)
                                .snapshots(),
                            builder: (context, resultsSnap) {
                              if (resultsSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 18),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.amber,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (resultsSnap.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'ত্রুটি: ${resultsSnap.error}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              final resultDocs = resultsSnap.data?.docs ?? [];
                              int totalQuestions = 0;
                              int correctAnswers = 0;
                              int bestPercent = 0;
                              final categoriesPlayed = <String>{};

                              for (final d in resultDocs) {
                                final data = d.data() as Map<String, dynamic>;
                                final tq = ((data['totalQuestions'] ?? 0) as num).toInt();
                                final caRaw = data['correctAnswers'] ?? data['score'] ?? 0;
                                final ca = (caRaw as num).toInt();
                                final p = ((data['percentage'] ?? 0) as num).toInt();
                                totalQuestions += tq;
                                correctAnswers += ca;
                                if (p > bestPercent) bestPercent = p;
                                categoriesPlayed.add(
                                  (data['categoryTitle'] ??
                                          data['category'] ??
                                          '')
                                      .toString(),
                                );
                              }

                              final avgAccuracy = totalQuestions > 0
                                  ? (correctAnswers / totalQuestions).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0.0;

                              final quizEntries = resultDocs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                final rawTs =
                                    data['updatedAt'] ?? data['timestamp'];
                                return {
                                  'title':
                                      (data['categoryTitle'] ??
                                              data['category'] ??
                                              '')
                                          .toString(),
                                  'score': ((data['percentage'] ?? 0) as num).toInt(),
                                  'date': _formatDate(rawTs),
                                };
                              }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Overall Stats',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ).animate().fadeIn(delay: 200.ms),
                                  const SizedBox(height: 15),
                                  GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.55,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    children: [
                                      _AnimatedStatCard(
                                        title: 'Total Questions',
                                        value: '$totalQuestions',
                                        icon: Icons.menu_book,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1DE9B6),
                                            Color(0xFF00BFA5),
                                          ],
                                        ),
                                        accentColor: Colors.tealAccent,
                                        trend: 'Live',
                                      ),
                                      _AnimatedStatCard(
                                        title: 'Correct Answers',
                                        value: '$correctAnswers',
                                        icon: Icons.check_circle_outline,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD54F),
                                            Color(0xFFFFA000),
                                          ],
                                        ),
                                        accentColor: Colors.amber,
                                        trend:
                                            '${(avgAccuracy * 100).round()}%',
                                      ),
                                      _AnimatedStatCard(
                                        title: 'Categories Played',
                                        value:
                                            '${categoriesPlayed.where((e) => e.isNotEmpty).length}',
                                        icon: Icons.category_outlined,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFBA68C8),
                                            Color(0xFF9C27B0),
                                          ],
                                        ),
                                        accentColor: Colors.purpleAccent,
                                        trend: 'unique',
                                      ),
                                      _AnimatedStatCard(
                                        title: 'Best Score',
                                        value: '$bestPercent%',
                                        icon: Icons.emoji_events_outlined,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF4FC3F7),
                                            Color(0xFF03A9F4),
                                          ],
                                        ),
                                        accentColor: Colors.lightBlueAccent,
                                        trend: 'best',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 36),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(
                                                  0.25,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.trending_up_rounded,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Overall Performance',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        Center(
                                          child: _AnimatedCircularProgress(
                                            value: avgAccuracy,
                                            label: 'Avg Accuracy',
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.amber,
                                                Colors.orange,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quiz History',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Last 30 Days',
                                          style: GoogleFonts.inter(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('activities')
                                        .orderBy('timestamp', descending: true)
                                        .limit(8)
                                        .snapshots(),
                                    builder: (context, actSnap) {
                                      if (actSnap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.amber,
                                                ),
                                          ),
                                        );
                                      }

                                      if (actSnap.hasError) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              'ত্রুটি: ${actSnap.error}',
                                              style: GoogleFonts.inter(
                                                color: Colors.white70,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      }

                                      final docs = actSnap.data?.docs ?? [];
                                      if (docs.isEmpty) {
                                        return Text(
                                          'No history yet',
                                          style: GoogleFonts.inter(
                                            color: Colors.white54,
                                          ),
                                        );
                                      }

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 18,
                                              crossAxisSpacing: 18,
                                              childAspectRatio: 0.90,
                                            ),
                                        itemCount: docs.length,
                                        itemBuilder: (context, index) {
                                          final data =
                                              docs[index].data()
                                                  as Map<String, dynamic>;
                                          final percent =
                                              ((data['score'] ?? 0) as num).toInt();
                                          final title =
                                              (data['title'] ?? 'Quiz')
                                                  .toString();
                                          final ts = data['timestamp'];
                                          final date = _formatDate(ts);

                                          final quizData = {
                                            'num': index + 1,
                                            'percent': percent,
                                            'date': date,
                                            'improving': index == 0,
                                            'title': title,
                                          };

                                          return _AnimatedQuizCard(
                                                quizNum: index + 1,
                                                percent: percent,
                                                date: date,
                                                isImproving: index == 0,
                                                onTap: () =>
                                                    _showQuizDetailDialog(
                                                      context,
                                                      quizData,
                                                    ),
                                              )
                                              .animate()
                                              .fadeIn(delay: (index * 60).ms)
                                              .scale(
                                                begin: const Offset(0.85, 0.85),
                                                curve: Curves.easeOutBack,
                                              );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 48),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD54F),
                                          Color(0xFFFFB74D),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _AnimatedActionButton(
                                      onPressed: () async {
                                        try {
                                          await _exportFullReport(
                                            context: context,
                                            totalQuestions: totalQuestions,
                                            correctAnswers: correctAnswers,
                                            bestPercent: bestPercent,
                                            avgAccuracy: avgAccuracy,
                                            quizEntries: quizEntries,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '📄 PDF report generated & opened!',
                                              ),
                                              backgroundColor: Color(
                                                0xFF1B5E20,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(16),
                                                ),
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to generate PDF: $e',
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                      label: 'Export Full Report',
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFullReport({
    required BuildContext context,
    required int totalQuestions,
    required int correctAnswers,
    required int bestPercent,
    required double avgAccuracy,
    required List<Map<String, dynamic>> quizEntries,
  }) async {
    final doc = pw.Document();

    final accuracyPercent = (avgAccuracy * 100)
        .clamp(0, 100)
        .toStringAsFixed(1);

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Quiz Detailed Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Overview',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(text: 'Total questions attempted: $totalQuestions'),
          pw.Bullet(text: 'Correct answers: $correctAnswers'),
          pw.Bullet(text: 'Best score: $bestPercent%'),
          pw.Bullet(text: 'Average accuracy: $accuracyPercent%'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Recent quiz history',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (quizEntries.isEmpty)
            pw.Text(
              'No quiz history available.',
              style: const pw.TextStyle(fontSize: 12),
            )
          else
            pw.Table.fromTextArray(
              headers: const ['Title', 'Score', 'Date'],
              data: quizEntries
                  .map(
                    (q) => [
                      q['title']?.toString() ?? '-',
                      '${q['score'] ?? 0}%',
                      q['date']?.toString() ?? '-',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    final fileName =
        'quiz_detailed_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    }
    if (ts is DateTime) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[ts.month - 1]} ${ts.day}';
    }
    return '';
  }

  void _showQuizDetailDialog(
    BuildContext context,
    Map<String, dynamic> quizData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2C3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Quiz #${quizData['num']} Breakdown',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${quizData['percent']}% ',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
                  ),
                  if ((quizData['percent'] as int) >= 90)
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow(
              'Correct Answers',
              '10 / 10',
              Colors.greenAccent,
            ),
            _buildBreakdownRow('Time Taken', '4 min 12 sec', Colors.white70),
            _buildBreakdownRow(
              'Category',
              (quizData['title'] ?? 'Quiz').toString(),
              Colors.tealAccent,
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const Text(
              'You smashed it! 🔥',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review mode coming soon in next update!'),
                ),
              );
            },
            child: Text(
              'Review Questions',
              style: GoogleFonts.inter(color: Colors.amber),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Custom Widgets
class _AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final String trend;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.trend,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child:
          AnimatedContainer(
                clipBehavior: Clip.hardEdge,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _isHovered
                      ? LinearGradient(
                          colors: [
                            widget.gradient.colors[0].withOpacity(0.85),
                            widget.gradient.colors[1].withOpacity(0.85),
                          ],
                        )
                      : widget.gradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(
                      _isHovered ? 0.7 : 0.35,
                    ),
                    width: _isHovered ? 2.5 : 1.5,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.value,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.trend,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.92, 0.92)),
    );
  }
}

class _AnimatedCircularProgress extends StatefulWidget {
  final double value;
  final String label;
  final Gradient gradient;

  const _AnimatedCircularProgress({
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  State<_AnimatedCircularProgress> createState() =>
      _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<_AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(160, 160),
              painter: _GradientCircularProgressPainter(
                progress: _animation.value,
                gradient: widget.gradient,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _animation.value * 100),
                  duration: const Duration(milliseconds: 1800),
                  builder: (_, value, __) => Text(
                    '${value.round()}%',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final Gradient gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const stroke = 11.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = gradient.createShader(rect);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28 * progress,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedQuizCard extends StatefulWidget {
  final int quizNum;
  final int percent;
  final String date;
  final bool isImproving;
  final VoidCallback onTap;

  const _AnimatedQuizCard({
    required this.quizNum,
    required this.percent,
    required this.date,
    required this.isImproving,
    required this.onTap,
  });

  @override
  State<_AnimatedQuizCard> createState() => _AnimatedQuizCardState();
}

class _AnimatedQuizCardState extends State<_AnimatedQuizCard> {
  bool _isPressed = false;

  Color _getColor() {
    if (widget.percent >= 90) return Colors.greenAccent;
    if (widget.percent >= 75) return Colors.amber;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getColor().withOpacity(0.3), width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz #${widget.quizNum}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              Text(
                widget.date,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.percent}%',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _getColor(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.percent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              if (widget.isImproving)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.greenAccent,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _AnimatedActionButton({required this.onPressed, this.label = 'Open'});

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _pressed
            ? (Matrix4.identity()..scale(0.94))
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.file_download_outlined,
              color: Colors.black87,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
