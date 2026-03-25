import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialConnectSection extends StatelessWidget {
  const SocialConnectSection({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final socials = [
      (Icons.facebook, Color(0xFF1877F2), 'https://facebook.com/yourpage'),
      (Icons.telegram, Color(0xFF0088cc), 'https://t.me/yourchannel'),
      (Icons.chat, Color(0xFF25D366), 'https://wa.me/8801xxxxxxxxx'),
      (
        Icons.youtube_searched_for,
        Color(0xFFFF0000),
        'https://youtube.com/@YourChannel',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B6B3A),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: socials.map((e) {
              final (icon, color, url) = e;
              return IconButton(
                icon: Icon(icon, color: color, size: 32),
                onPressed: () => _launch(url),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
