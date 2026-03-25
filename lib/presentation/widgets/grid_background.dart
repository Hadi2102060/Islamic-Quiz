// lib/presentation/widgets/grid_background.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GridBackground extends StatelessWidget {
  const GridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
        ),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return Container(
                margin: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12 + (index % 5) * 0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
              .animate(delay: (index % 20 * 40).ms)
              .fadeIn(duration: 1200.ms)
              .scale(
                delay: (index % 20 * 50).ms,
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOutSine,
              )
              .then(delay: 2000.ms)
              .shimmer(duration: 1800.ms, color: Colors.white.withOpacity(0.4));
        },
      ),
    );
  }
}
