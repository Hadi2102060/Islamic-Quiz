import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Islamic Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Islamic Quiz',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 12),
            Text(
              'Islamic Quiz is designed to help learners improve Islamic knowledge through short and engaging quizzes.',
            ),
            SizedBox(height: 16),
            Text(
              'What you can do:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('• Play category-wise quizzes'),
            Text('• Track leaderboard ranking'),
            Text('• Review your personal results'),
            Text('• Complete profile and keep progress synced'),
            SizedBox(height: 16),
            Text(
              'Mission:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'To make Islamic learning accessible, interactive, and motivating for everyone.',
            ),
            SizedBox(height: 16),
            Text(
              'Thanks for using Islamic Quiz. May Allah increase us in beneficial knowledge.',
            ),
          ],
        ),
      ),
    );
  }
}
