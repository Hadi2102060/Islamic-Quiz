import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/glass_card.dart';
import '../../domain/entities/quiz_category.dart';
import 'quiz_state.dart';
import 'quiz_viewmodel.dart';
import '../router/app_router.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.category, this.restart = false});

  final QuizCategory category;
  final bool restart;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  bool _performedRestart = false;

  @override
  void initState() {
    super.initState();
    // nothing here; we will use didChangeDependencies to access ref safely
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.restart && !_performedRestart) {
      _performedRestart = true;
      // schedule after frame to ensure providers are available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = ref.read(
          quizViewModelProvider(widget.category.questions).notifier,
        );
        viewModel.restart();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizViewModelProvider(widget.category.questions));
    final viewModel = ref.read(
      quizViewModelProvider(widget.category.questions).notifier,
    );
    final question = state.questions[state.currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Deep gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF071B2F), Color(0xFF073E3A)],
              ),
            ),
          ),

          // Subtle Lottie decoration
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, right: 8),
                    child: SizedBox(
                      width: 320,
                      child: Lottie.asset(
                        'assets/lottie_files/Islamic_shape.json',
                        repeat: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
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
                      Expanded(
                        child: Text(
                          widget.category.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildProgress(context, state),

                  const SizedBox(height: 18),

                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.96, end: 1.0),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    builder: (context, double scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${state.currentIndex + 1} / ${state.questions.length}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.question,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final opts = question.options;
                              final cross = opts.length == 2 ? 1 : 2;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: cross,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: cross == 1
                                    ? 6
                                    : (constraints.maxWidth / cross) / 60,
                                children: List.generate(opts.length, (index) {
                                  final option = opts[index];
                                  final isSelected =
                                      state.selectedOptionIndex == index;
                                  final isCorrect =
                                      question.correctIndex == index;
                                  final showFeedback =
                                      state.selectedOptionIndex != -1;

                                  Color borderColor() {
                                    if (!showFeedback) return Colors.white12;
                                    if (isCorrect)
                                      return Colors.greenAccent.shade400;
                                    if (isSelected)
                                      return Colors.redAccent.shade200;
                                    return Colors.white24;
                                  }

                                  return _OptionTile(
                                    label: option,
                                    index: index,
                                    isSelected: isSelected,
                                    isCorrect: isCorrect,
                                    showFeedback: showFeedback,
                                    onTap: () => viewModel.selectOption(index),
                                    borderColor: borderColor(),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  _buildFooter(context, state, viewModel, widget.category),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Option tile with hover and press animations and feedback state
class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
    required this.borderColor,
  });

  final String label;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(12),
            splashColor: widget.isSelected ? Colors.white24 : Colors.white12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? (widget.isCorrect
                          ? Colors.green.shade800.withOpacity(0.18)
                          : Colors.red.shade700.withOpacity(0.12))
                    : Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: (_hovered || widget.isSelected)
                        ? widget.borderColor.withOpacity(0.18)
                        : Colors.black12,
                    blurRadius: _hovered ? 18 : 6,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: _pressed ? 36 : 42,
                    height: _pressed ? 36 : 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.isSelected
                          ? LinearGradient(
                              colors: [
                                widget.isCorrect
                                    ? Colors.greenAccent.shade400
                                    : Colors.redAccent.shade200,
                                Colors.amber.shade400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF0B6B3A), Color(0xFF1B9C5A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isSelected
                              ? widget.borderColor.withOpacity(0.22)
                              : Colors.black26.withOpacity(0.06),
                          blurRadius: _hovered ? 12 : 6,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        color: widget.isSelected
                            ? Colors.black87
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isSelected
                            ? (widget.isCorrect
                                  ? Colors.greenAccent.shade100
                                  : Colors.redAccent.shade100)
                            : Colors.white,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        height: 1.18,
                      ),
                    ),
                  ),
                  if (widget.showFeedback &&
                      (widget.isCorrect || widget.isSelected))
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: widget.showFeedback ? 1.0 : 0.0,
                      child: Icon(
                        widget.isCorrect ? Icons.check_circle : Icons.cancel,
                        color: widget.isCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildProgress(BuildContext context, QuizState state) {
  final progress = (state.currentIndex + 1) / state.questions.length;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'সময় বাকি: ${state.remainingSeconds}s',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const Spacer(),
          Text(
            'স্কোর: ${state.score}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 12,
          color: Colors.white12,
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFF1DE9B6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // subtle shimmer line
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (progress.clamp(0.0, 1.0)),
                    child: Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildFooter(
  BuildContext context,
  QuizState state,
  QuizViewModel viewModel,
  QuizCategory category,
) {
  if (state.isCompleted) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'স্কোর: ${state.score}/${state.questions.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Gradient primary button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFF1DE9B6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppRouter.router.go(
                      '${AppRouter.result}?score=${state.score}&total=${state.questions.length}',
                      extra: category,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'ফলাফল দেখুন',
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _RestartButton(
              onPressed: viewModel.restart,
              label: 'পুনরায় শুরু করুন',
            ),
          ],
        ),
      ),
    );
  }

  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Text(
        state.selectedOptionIndex == -1
            ? 'উত্তরটি নির্বাচিত করতে ট্যাপ করুন।'
            : 'পরবর্তী প্রশ্নের জন্য অপেক্ষা করুন...',
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _RestartButton extends StatefulWidget {
  const _RestartButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  State<_RestartButton> createState() => _RestartButtonState();
}

class _RestartButtonState extends State<_RestartButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hover
                  ? [Color(0xFF4A148C), Color(0xFF283593)]
                  : [Color(0xFF512DA8), Color(0xFF303F9F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _hover ? Colors.black26 : Colors.black12,
                blurRadius: _hover ? 18 : 6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onPressed,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              splashColor: Colors.white24,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
