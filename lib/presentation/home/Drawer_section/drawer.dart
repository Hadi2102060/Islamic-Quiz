import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/providers/sound_provider.dart';
import 'package:quiz_app/data/providers/auth_providers.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/services/audio_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen>
    with SingleTickerProviderStateMixin {
  Future<void> _openContactEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com', // তোমার আসল ইমেইল দাও
      queryParameters: {
        'subject': 'Inquiry from YourApp',
        'body': 'Hello,\n\nI have a question regarding...\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      print('Could not launch email');
      // optional: SnackBar দেখাতে পারো "No email app found"
    }
  }

  Future<void> _shareApp() async {
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.yourcompany.yourapp';
    const String message =
        'আমি এই অসাধারণ কুইজ অ্যাপটা ব্যবহার করছি! তুমিও ট্রাই করে দেখো 🔥\n\n$appLink';

    try {
      await Share.share(
        message,
        subject: 'Invite friends to Our Islamic Quiz App',
      );
    } catch (e) {
      print('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        top: true, // ← status bar এর নিচে থাকবে
        bottom: false,
        left: false,
        right: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated Drawer Header
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.translate(
                      offset: Offset(0, -20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildAnimatedHeader(),
              ),

              // Main Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    // Main Menu Items with Animation
                    _buildAnimatedMenuItem(
                      index: 0,
                      child: _buildMainMenuItems(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Divider(thickness: 1, color: Color(0xFF0B6B3A)),
                    ),

                    // Quick Actions Grid
                    _buildAnimatedMenuItem(
                      index: 1,
                      child: _buildQuickActionsGrid(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Divider(thickness: 1, color: Color(0xFF0B6B3A)),
                    ),

                    // Social/Contact Section
                    _buildAnimatedMenuItem(
                      index: 2,
                      child: _buildSocialSection(),
                    ),

                    const SizedBox(height: 20),

                    // User Profile Card
                    _buildAnimatedMenuItem(
                      index: 3,
                      child: _buildUserProfileCard(context),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B6B3A), Color(0xFF1B9C5A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6B3A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle header tap if needed
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Quran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Test Your Knowledge',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    // Helper function to launch URL safely
    Future<void> _launchUrl(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // opens in native app if installed, else browser
        );
      } else {
        // Optional: show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

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
            children: [
              // Facebook Page
              _buildSocialIcon(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                onTap: () {
                  // Replace with your real page username or ID
                  _launchUrl('https://www.facebook.com');
                  // Alternative deep link (tries to open app first):
                  // _launchUrl('fb://facewebmodal/f?href=https://www.facebook.com/yourpageusername');
                },
              ),

              // Telegram Channel
              _buildSocialIcon(
                icon: Icons.telegram,
                color: const Color(0xFF0088cc),
                onTap: () {
                  // Replace @YourChannelName with real channel username (with @)
                  _launchUrl('https://t.me');
                  // or deep link: 'tg://join/?invite=AAAAAE....' for private groups
                },
              ),

              // WhatsApp (group or support chat)
              _buildSocialIcon(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                onTap: () {
                  // Option 1: Open WhatsApp with pre-filled message to a number
                  // Replace 88017xxxxxxxx with real number (include country code, no + or 0)
                  const phone = '88017xxxxxxxx';
                  const message = 'Hello! I came from your app';
                  _launchUrl(
                    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
                  );

                  // Option 2: If you have a WhatsApp group invite link
                  // _launchUrl('https://chat.whatsapp.com/xxxxxxxxxxxx');
                },
              ),

              // YouTube Channel - Hadidevhub
              _buildSocialIcon(
                icon: Icons.youtube_searched_for,
                color: const Color(0xFFFF0000),
                onTap: () {
                  // Replace with your real channel handle or ID
                  // Option 1: Modern handle (recommended)
                  _launchUrl('https://www.youtube.com/@HadiDevHub');

                  // Option 2: Channel ID (if no handle)
                  // _launchUrl('https://www.youtube.com/channel/UCxxxxxxxxxxxxxxxxxxxxxx');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authAsync = ref.watch(authStateChangesProvider);

        return authAsync.when(
          data: (User? user) {
            // If FirebaseAuth user exists, show email-auth card.
            if (user != null) return _buildLoggedInProfileCard(context, user);

            // Otherwise, check SharedPreferences phone-based login.
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final prefs = snap.data!;
                final phone = prefs.getString('userPhone')?.trim() ?? '';
                final userId =
                    (prefs.getString('userId')?.trim().isNotEmpty == true)
                    ? prefs.getString('userId')!.trim()
                    : phone.replaceAll(RegExp(r'[^0-9]'), '');

                // No phone saved -> true guest.
                if (phone.isEmpty) return _buildGuestProfileCard(context);

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final data = userSnap.data?.data() ?? <String, dynamic>{};

                    final name = (data['name'] ?? 'Unknown User').toString();
                    final email = (data['email'] ?? 'Unknown').toString();
                    final profileCompleted = data['profileCompleted'] == true;

                    return InkWell(
                      onTap: () {
                        if (profileCompleted) {
                          AppRouter.router.push(AppRouter.profile);
                          return;
                        }

                        context.go(AppRouter.profile);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0B6B3A).withOpacity(0.12),
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0B6B3A).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0B6B3A),
                                    Color(0xFF1B9C5A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!profileCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Complete',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF8A5A00),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    email == 'Unknown' ? phone : email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              profileCompleted
                                  ? Icons.chevron_right
                                  : Icons.edit,
                              color: const Color(0xFF0B6B3A),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, st) => Text('Auth error: $err'),
        );
      },
    );
  }

  // ─── Guest (not logged in) version ──────────────────────────────
  Widget _buildGuestProfileCard(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go(AppRouter.login);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0B6B3A).withOpacity(0.12), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0B6B3A).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B6B3A), Color(0xFF1B9C5A)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unknown User',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Sign in for more features & progress saving',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFF0B6B3A),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.go(AppRouter.login);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Logged-in version ───────────────────────────────────────────
  Widget _buildLoggedInProfileCard(BuildContext context, User user) {
    final displayName = user.displayName ?? 'User';
    final photoUrl = user.photoURL;
    final email = user.email ?? 'No email';

    return InkWell(
      onTap: () {
        // Go to full profile screen
        AppRouter.router.push(AppRouter.profile);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0B6B3A).withOpacity(0.15), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0B6B3A).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Profile picture
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0B6B3A), width: 2.2),
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photoUrl == null
                  ? CircleAvatar(
                      backgroundColor: const Color(0xFF0B6B3A),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email.length > 28 ? '${email.substring(0, 25)}...' : email,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Logout button (small)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Sign out',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // Optional: show snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoverableListTile({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, key: ValueKey(isHovered), color: color),
              ),
              title: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              trailing: null,
              onTap: onTap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF0B6B3A).withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B6B3A),
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption('English', '🇬🇧'),
            _buildLanguageOption('Bangla', '🇧🇩'),
            _buildLanguageOption('Arabic', '🇸🇦'),
            _buildLanguageOption('Urdu', '🇵🇰'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String flag) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, language),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0B6B3A).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(language, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF0B6B3A),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMenuItem({required int index, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutQuad,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B6B3A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              _buildGridActionItem(
                icon: Icons.help_outline,
                label: 'Help',
                color: Colors.blue.shade700,
                onTap: () {
                  Navigator.of(context).pop();
                  AppRouter.router.go(AppRouter.help); // সাহায্য স্ক্রিনে যান
                },
              ),
              _buildGridActionItem(
                icon: Icons.mail_outline,
                label: 'Contact',
                color: Colors.blue,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _openContactEmail(); // ইমেইল খুলবে
                },
              ),
              _buildGridActionItem(
                icon: Icons.info_outline,
                label: 'About',
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).pop();
                  AppRouter.router.go(AppRouter.about); // তোমার আগের মতোই
                },
              ),
              _buildGridActionItem(
                icon: Icons.share_outlined,
                label: 'Share',
                color: Colors.green,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _shareApp(); // শেয়ার শীট খুলবে (FB, Messenger, etc)
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        // ignore: deprecated_member_use
        Color backgroundStart = color.withOpacity(0.14);
        // ignore: deprecated_member_use
        Color backgroundEnd = color.withOpacity(0.06);

        return MouseRegion(
          onEnter: (_) => setState(() as VoidCallback),
          onExit: (_) => setState(() as VoidCallback),
          child: GestureDetector(
            onTapDown: (_) => setState(() as VoidCallback),
            onTapUp: (_) => setState(() as VoidCallback),
            onTapCancel: () => setState(() as VoidCallback),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [backgroundStart, backgroundEnd],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.02),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                // ignore: deprecated_member_use
                splashColor: color.withOpacity(0.12),
                // ignore: deprecated_member_use
                highlightColor: color.withOpacity(0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            // ignore: deprecated_member_use
                            color.withOpacity(0.95),
                            // ignore: deprecated_member_use
                            color.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: color.withOpacity(0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: color.withOpacity(0.9)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainMenuItems() {
    return Column(
      children: [
        _buildHoverableListTile(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          title: 'Home',
          onTap: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const AudioToggleScreen(),
            //   ),
            // );
            Navigator.of(context).pop();
            AppRouter.router.go(AppRouter.home);
          },
          color: const Color(0xFF0B6B3A),
        ),

        // Sound Toggle with State Management
        Consumer(
          builder: (context, ref, _) {
            final soundOn = ref.watch(soundOnProvider);
            return _buildHoverableListTile(
              icon: soundOn
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
              selectedIcon: soundOn ? Icons.volume_up : Icons.volume_off,
              title: soundOn ? 'Sound On' : 'Sound Off',
              onTap: () async {
                final newState = !soundOn;
                ref.read(soundOnProvider.notifier).state = newState;

                final audioService = AudioService();
                if (newState) {
                  await audioService.play();
                } else {
                  await audioService.pause();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Sound ${newState ? 'enabled' : 'disabled'}"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              color: const Color(0xFF0B6B3A),
            );
          },
        ),
        _buildHoverableListTile(
          icon: Icons.language_outlined,
          selectedIcon: Icons.language,
          title: 'Languages',
          onTap: () async {
            Navigator.of(context).pop();
            final choice = await showDialog<String>(
              context: context,
              builder: (_) => _buildLanguageDialog(),
            );
            if (choice != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🌐 Language: $choice'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          color: const Color(0xFF0B6B3A),
        ),
        _buildHoverableListTile(
          icon: Icons.favorite_border,
          selectedIcon: Icons.favorite,
          title: 'Invite Friends',
          onTap: () async {
            Navigator.of(context).pop(); // close the drawer first

            const appLink =
                'https://example.com'; // ← Replace with your real app link (Play Store / App Store / website)
            const shareText =
                'Check out this awesome Quran Quiz app!\n$appLink\nTest your knowledge of the Quran in a fun & rewarding way! 📖✨';

            try {
              await SharePlus.instance.share(
                ShareParams(
                  text: shareText,
                  subject:
                      'Invite to Quran Quiz App', // optional – good for email/share targets that support subject
                  // sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1), // optional – only needed on iPad/macOS or if targeting iOS 26+ iPhones without issues
                ),
              );

              // Optional: You can check result.status if you want platform-specific feedback
              // result.status == ShareResultStatus.success / dismissed / unavailable
              // But usually not needed for simple invites – most apps skip this

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Shared successfully! 🎉'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share failed: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          color: Colors.red,
        ),
      ],
    );
  }
}
