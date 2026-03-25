import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class StatsBackground extends StatelessWidget {
  const StatsBackground({
    super.key,
    required this.child,
    this.lottieAlignment = Alignment.topRight,
  });

  final Widget child;
  final Alignment lottieAlignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background (same style as StatsScreen)
        AnimatedContainer(
          duration: const Duration(seconds: 3),
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

        // Lottie decoration
        Align(
          alignment: lottieAlignment,
          child: Opacity(
            opacity: 0.12,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/lottie_files/Islamic_shape.json',
                repeat: true,
              ),
            ),
          ),
        ),

        // Floating particles
        ...List.generate(
          3,
          (index) => Positioned(
            left: (index * 80.0) % 300,
            top: (index * 100.0) % 600,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            )
                .animate()
                .fadeIn(duration: 1000.ms, delay: (index * 200).ms)
                .then()
                .shimmer(duration: 2000.ms, color: Colors.white24)
                .then()
                .moveY(
                  begin: 0,
                  end: 15,
                  duration: 3000.ms,
                  curve: Curves.easeInOut,
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ),
          ),
        ),

        child,
      ],
    );
  }
}

