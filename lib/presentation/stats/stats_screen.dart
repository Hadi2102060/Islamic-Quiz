import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/presentation/widgets/stats_background.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // Navigation history may not exist depending on how we arrived here.
        // Always route back to Home to guarantee expected behavior.
        AppRouter.router.go(AppRouter.home);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StatsBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          // Header
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
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20, // Fixed icon size
                                    ),
                                  ),
                                ),
                              ).animate().scale(
                                duration: 300.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                    child: Text(
                                      'Statistics',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 20, // Reduced font size
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 100.ms)
                                  .slideX(begin: -0.2, end: 0),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (user == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Center(
                                child: Text(
                                  'Sign in to see your statistics',
                                  style: GoogleFonts.inter(color: Colors.white70),
                                ),
                              ),
                            )
                          else
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('activities')
                                  .orderBy('timestamp', descending: true)
                                  .limit(50)
                                  .snapshots(),
                              builder: (context, activitySnap) {
                                if (activitySnap.connectionState ==
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

                                final activityDocs = activitySnap.data?.docs ?? [];
                                final totalQuizzes = activityDocs.length;
                                final scores = activityDocs
                                    .map(
                                      (d) => ((d.data() as Map<String, dynamic>)['score'] ??
                                              0)
                                          as int,
                                    )
                                    .toList();
                                final bestScore =
                                    scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);
                                final avgScore = scores.isEmpty
                                    ? 0
                                    : (scores.reduce((a, b) => a + b) / scores.length);

                                final recent = activityDocs.take(5).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Summary cards
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _AnimatedStatCard(
                                            title: 'Total Quizzes',
                                            value: '$totalQuizzes',
                                            icon: Icons.quiz_outlined,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFFFD54F),
                                                Color(0xFFFFA000),
                                              ],
                                            ),
                                            accentColor: Colors.amber,
                                            trend: totalQuizzes > 0 ? 'Live' : '0',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _AnimatedStatCard(
                                            title: 'Best Score',
                                            value: '$bestScore%',
                                            icon: Icons.emoji_events_outlined,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF1DE9B6),
                                                Color(0xFF00BFA5),
                                              ],
                                            ),
                                            accentColor: Colors.tealAccent,
                                            trend: 'Best',
                                          ),
                                        ),
                                      ],
                                    ),

                          const SizedBox(height: 16),

                          // Circular progress with accuracy
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.trending_up_rounded,
                                        color: Colors.amber.shade200,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Performance',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: _AnimatedCircularProgress(
                                    value: (avgScore / 100).clamp(0.0, 1.0),
                                    label: 'Avg Accuracy',
                                    gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Recent Scores Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Scores',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Last 5',
                                        style: GoogleFonts.inter(
                                          color: Colors.greenAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (recent.isEmpty)
                                  Text(
                                    'No recent scores yet',
                                    style: GoogleFonts.inter(color: Colors.white54),
                                  )
                                else
                                  ...List.generate(recent.length, (index) {
                                    final data =
                                        recent[index].data() as Map<String, dynamic>;
                                    final percent = (data['score'] ?? 0) as int;
                                    final title = (data['title'] ?? 'Quiz').toString();
                                    final isImproving = index == 0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _AnimatedRecentScore(
                                        index: index,
                                        percent: percent,
                                        isImproving: isImproving,
                                        title: title,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Footer CTA
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD54F),
                                      Color(0xFFFFB74D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Detailed Stats',
                                            style: GoogleFonts.inter(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Analytics',
                                            style: GoogleFonts.inter(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _AnimatedActionButton(
                                      onPressed: () {
                                        AppRouter.router.go(AppRouter.detailStats);
                                      },
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                          // Extra bottom padding
                          const SizedBox(height: 20),
                                  ],
                                );
                              },
                            ),
                        ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _isHovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.gradient.colors[0].withOpacity(0.9),
                        widget.gradient.colors[1].withOpacity(0.9),
                      ],
                    )
                  : widget.gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accentColor.withOpacity(_isHovered ? 0.5 : 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.value,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.trend,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
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
          ),
        )
        .animate()
        .fadeIn(
          duration: 500.ms,
          delay: (widget.title == 'Total Quizzes' ? 200 : 300).ms,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutBack,
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
      duration: const Duration(milliseconds: 1500),
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
      builder: (context, child) {
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _GradientCircularProgressPainter(
                    progress: _animation.value,
                    gradient: widget.gradient,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _animation.value * 100),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Text(
                        '${value.round()}%',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    final radius = size.width / 2;
    final strokeWidth = 10.0;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress circle with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = gradient.createShader(rect);

    final progressPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -90 * (3.14159 / 180),
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedRecentScore extends StatefulWidget {
  final int index;
  final int percent;
  final bool isImproving;
  final String title;

  const _AnimatedRecentScore({
    required this.index,
    required this.percent,
    required this.isImproving,
    this.title = 'Quiz',
  });

  @override
  State<_AnimatedRecentScore> createState() => _AnimatedRecentScoreState();
}

class _AnimatedRecentScoreState extends State<_AnimatedRecentScore>
    with SingleTickerProviderStateMixin {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHighlighted = true),
          onExit: (_) => setState(() => _isHighlighted = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: _isHighlighted
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Quiz number
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _getScoreColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: GoogleFonts.inter(
                        color: _getScoreColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: widget.percent / 100),
                              duration: Duration(
                                milliseconds: 800 + (widget.index * 100),
                              ),
                              builder: (context, value, child) {
                                return Container(
                                  height: 4,
                                  width:
                                      MediaQuery.of(context).size.width *
                                      0.35 *
                                      value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getScoreColor(),
                                        _getScoreColor().withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.percent}%',
                        style: GoogleFonts.inter(
                          color: _getScoreColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.isImproving) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.trending_up,
                          color: Colors.greenAccent,
                          size: 10,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: (600 + widget.index * 100).ms)
        .slideX(begin: 0.2, end: 0);
  }

  Color _getScoreColor() {
    if (widget.percent >= 90) return Colors.greenAccent;
    if (widget.percent >= 70) return Colors.amber;
    if (widget.percent >= 50) return Colors.orange;
    return Colors.redAccent;
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedActionButton({required this.onPressed});

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: _isPressed
          ? (Matrix4.identity()..scale(0.95))
          : Matrix4.identity(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Text(
              'Open',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}
