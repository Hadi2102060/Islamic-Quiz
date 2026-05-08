import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialConnectSection extends StatelessWidget {
  const SocialConnectSection({super.key});

  Future<void> _launchPreferred({
    required String appUrl,
    required String webUrl,
  }) async {
    final appUri = Uri.parse(appUrl);
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse(webUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socials = [
      (
        Icons.facebook,
        const Color(0xFF1877F2),
        'fb://facewebmodal/f?https://www.facebook.com/share/15mw3zdJnfT/',
        'https://www.facebook.com/share/15mw3zdJnfT/',
      ),
      (
        Icons.telegram,
        const Color(0xFF0088cc),
        'tg://resolve?domain=HadiDevHub',
        'https://t.me/HadiDevHub',
      ),
      (
        Icons.chat,
        const Color(0xFF25D366),
        'whatsapp://send?phone=8801700000000',
        'https://wa.me/8801700000000',
      ),
      (
        Icons.youtube_searched_for,
        const Color(0xFFFF0000),
        'vnd.youtube://www.youtube.com/@HadiDevHub',
        'https://www.youtube.com/@HadiDevHub',
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
              final (icon, color, appUrl, webUrl) = e;
              return IconButton(
                icon: Icon(icon, color: color, size: 32),
                onPressed: () =>
                    _launchPreferred(appUrl: appUrl, webUrl: webUrl),
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
