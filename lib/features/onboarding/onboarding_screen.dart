import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  final List<Widget> _pages = [
    _OnboardPage(
      title: 'Assalamu Alaikum',
      subtitle: 'Welcome to Islamic Quiz Game',
      lottieUrl: 'https://assets4.lottiefiles.com/packages/lf20_totrpclr.json',
    ),
    _OnboardPage(
      title: 'How to Play',
      subtitle: 'Multiple choice quizzes with a timer',
      lottieUrl: 'https://assets2.lottiefiles.com/packages/lf20_hzgq1iov.json',
    ),
    _OnboardPage(
      title: 'Categories',
      subtitle: 'Quran, Prophets, History and more',
      lottieUrl: 'https://assets6.lottiefiles.com/packages/lf20_kbrw0m9u.json',
    ),
    _OnboardPage(
      title: 'Get Started',
      subtitle: 'Sign up or continue as guest',
      lottieUrl:
          'https://assets6.lottiefiles.com/private_files/lf30_o5dhtpx5.json',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CarouselSlider(
                items: _pages,
                options: CarouselOptions(
                  height: double.infinity,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                  onPageChanged: (i, _) => setState(() => _index = i),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? Colors.green : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Proceed to auth or home
                      Navigator.of(context).pop();
                    },
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lottieUrl;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 260, child: Lottie.network(lottieUrl)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
