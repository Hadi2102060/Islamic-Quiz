import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  // 🔹 Help → dedicated help screen
  void _openHelp(BuildContext context) {
    context.push(AppRouter.help);
  }

  // 🔹 Contact → Facebook page link
  Future<void> _contact() async {
    final url = Uri.parse('https://www.facebook.com/share/1Ci2qXC3Mg/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  // 🔹 Share → Share sheet
  Future<void> _share() async {
    try {
      await Share.share(
        'Assalamu Alaikum! Check out this beautiful Quran Quiz app!\nLearn & test your knowledge of the Quran in a fun & rewarding way 📖✨.  To join this app : https://www.flicksize.com/islamic_quiz/',
        subject: 'Quran Quiz App - Join & Learn',
      );
    } catch (_) {
      debugPrint('Failed to share');
    }
  }

  // 🔹 About → dedicated screen
  void _openAbout(BuildContext context) {
    context.push(AppRouter.about);
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.help_outline_rounded,
        'Help',
        Colors.indigo.shade600,
        () => _openHelp(context),
      ),
      (Icons.mail_rounded, 'Contact', Colors.blue.shade700, _contact),
      (
        Icons.info_rounded,
        'About',
        Colors.purple.shade600,
        () => _openAbout(context),
      ),
      (Icons.share_rounded, 'Share', Colors.green.shade700, _share),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 8, 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B6B3A),
                letterSpacing: 0.4,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.28,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final (icon, label, baseColor, callback) = actions[index];
              return _BeautifulActionTile(
                icon: icon,
                label: label,
                baseColor: baseColor,
                onTap: () {
                  Navigator.pop(context); // drawer close
                  callback();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BeautifulActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color baseColor;
  final VoidCallback onTap;

  const _BeautifulActionTile({
    required this.icon,
    required this.label,
    required this.baseColor,
    required this.onTap,
  });

  @override
  State<_BeautifulActionTile> createState() => _BeautifulActionTileState();
}

class _BeautifulActionTileState extends State<_BeautifulActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool hover) {
    setState(() => _isHovered = hover);
    if (hover)
      _controller.forward();
    else
      _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.baseColor;
    final bgOpacity = _isPressed ? 0.22 : (_isHovered ? 0.16 : 0.08);
    final borderOpacity = _isPressed ? 0.60 : (_isHovered ? 0.45 : 0.22);
    final shadowBlur = _isPressed ? 20.0 : (_isHovered ? 16.0 : 8.0);
    final shadowOffset = _isPressed ? 5.0 : (_isHovered ? 4.0 : 2.0);

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: color.withOpacity(bgOpacity),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(borderOpacity),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.20),
                      blurRadius: shadowBlur,
                      offset: Offset(0, shadowOffset),
                      spreadRadius: _isHovered ? 1 : 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(-4, -4),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.05), Colors.transparent],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    splashColor: color.withOpacity(0.25),
                    highlightColor: color.withOpacity(0.15),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: color,
                            size: 36,
                            shadows: [
                              Shadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: color.withOpacity(0.95),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
