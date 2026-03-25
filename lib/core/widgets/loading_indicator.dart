import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 42,
        width: 42,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
