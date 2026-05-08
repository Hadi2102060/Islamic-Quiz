import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app/data/providers/session_user_provider.dart';

class MyResultsScreen extends ConsumerWidget {
  const MyResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdAsync = ref.watch(sessionUserIdProvider);
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                              onTap: () => Navigator.of(context).maybePop(),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'My Results',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      userIdAsync.when(
                        loading: () => const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        error: (err, _) => Expanded(
                          child: Center(
                            child: Text(
                              'Error loading results',
                              style: GoogleFonts.inter(color: Colors.white70),
                            ),
                          ),
                        ),
                        data: (userId) {
                          return Expanded(
                            child: userId == null
                                ? Center(
                                    child: Text(
                                      'Please sign in to see your results.',
                                      style: GoogleFonts.inter(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('results')
                                        .where('userId', isEqualTo: userId)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error loading results',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        );
                                      }

                                      if (snapshot.connectionState ==
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

                                      final docs = [...(snapshot.data?.docs ?? [])];
                                      docs.sort((a, b) {
                                        final aData = a.data() as Map<String, dynamic>;
                                        final bData = b.data() as Map<String, dynamic>;
                                        final aTime = _extractSortDate(
                                          aData['updatedAt'] ?? aData['createdAt'],
                                        );
                                        final bTime = _extractSortDate(
                                          bData['updatedAt'] ?? bData['createdAt'],
                                        );
                                        return bTime.compareTo(aTime);
                                      });
                                      if (docs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'এখনও কোনো ফলাফল নেই',
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        );
                                      }

                                      final resultItems = docs.map((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final categoryTitle =
                                            (data['categoryTitle'] ??
                                                    data['category'] ??
                                                    'Category')
                                                .toString();
                                        final score = _toInt(data['score']);
                                        final total = _toInt(
                                          data['totalQuestions'] ?? data['total'],
                                        );
                                        final percentageRaw = data['percentage'];
                                        final percentage = percentageRaw is num
                                            ? percentageRaw.toDouble()
                                            : (total > 0
                                                  ? (score / total * 100)
                                                  : 0.0);

                                        return _ResultItem(
                                          categoryTitle: categoryTitle,
                                          score: score,
                                          total: total,
                                          percentage: percentage,
                                          updatedAtText: _formatTimestamp(
                                            data['updatedAt'],
                                          ),
                                        );
                                      }).toList();

                                      final categoryMap =
                                          <String, List<_ResultItem>>{};
                                      for (final item in resultItems) {
                                        categoryMap.putIfAbsent(
                                          item.categoryTitle,
                                          () => <_ResultItem>[],
                                        );
                                        categoryMap[item.categoryTitle]!.add(
                                          item,
                                        );
                                      }

                                      final categories = categoryMap.keys
                                          .toList(growable: false);

                                      return ListView.separated(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        itemCount: categories.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final title = categories[index];
                                          final items = categoryMap[title]!;
                                          final best = items
                                              .map((e) => e.percentage)
                                              .fold<double>(
                                                0,
                                                (a, b) => a > b ? a : b,
                                              );

                                          return _CategoryResultCard(
                                            title: title,
                                            attempts: items,
                                            bestPercentage: best,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} • ${two(d.hour)}:${two(d.minute)}';
    }
    if (ts is DateTime) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(ts.day)}/${two(ts.month)}/${ts.year} • ${two(ts.hour)}:${two(ts.minute)}';
    }
    return '';
  }

  static DateTime _extractSortDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class _ResultItem {
  const _ResultItem({
    required this.categoryTitle,
    required this.score,
    required this.total,
    required this.percentage,
    required this.updatedAtText,
  });

  final String categoryTitle;
  final int score;
  final int total;
  final double percentage;
  final String updatedAtText;
}

class _CategoryResultCard extends StatelessWidget {
  const _CategoryResultCard({
    required this.title,
    required this.attempts,
    required this.bestPercentage,
  });

  final String title;
  final List<_ResultItem> attempts;
  final double bestPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${attempts.length} attempts • Best ${bestPercentage.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.amber.withOpacity(0.25)),
            ),
            child: Text(
              '${bestPercentage.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          children: attempts.map((item) => _ResultTile(item: item)).toList(),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item});

  final _ResultItem item;

  @override
  Widget build(BuildContext context) {
    final progress = item.total > 0
        ? (item.score / item.total).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${item.score}/${item.total}',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4ECDC4),
              ),
            ),
          ),
          if (item.updatedAtText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.updatedAtText,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}
