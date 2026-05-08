import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/core/providers/sound_notifier.dart';
import 'package:quiz_app/l10n/app_localizations.dart';
import 'package:quiz_app/presentation/home/Language_selector/show_language_selector.dart';
import 'package:quiz_app/presentation/home/components/drawer_header.dart';
import 'package:quiz_app/presentation/home/components/quick_actions_grid.dart';
import 'package:quiz_app/presentation/home/components/social_connect_section.dart';
import 'package:quiz_app/presentation/home/components/user_profile_card.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/login3.dart';
import 'package:quiz_app/presentation/router/app_router.dart';

// import your sound provider if needed

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const DrawerHeaderWidget(),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    // Main menu items (Home, Sound toggle, Language, Invite...)
                    _buildMainMenuItems(context, ref),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Divider(thickness: 1, color: Color(0xFF0B6B3A)),
                    ),

                    const QuickActionsGrid(),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Divider(thickness: 1, color: Color(0xFF0B6B3A)),
                    ),

                    const SocialConnectSection(),

                    const SizedBox(height: 20),

                    const _DrawerUserSection(),

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

  Widget _buildMainMenuItems(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home_outlined, color: Color(0xFF0B6B3A)),
          title: const Text(
            'Home',
            style: TextStyle(
              color: Color(0xFF0B6B3A),
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            // already on home
          },
        ),

        // HomeDrawer.dart এর _buildMainMenuItems এর ভিতরে sound toggle টা এভাবে রাখো
        Consumer(
          builder: (context, ref, _) {
            final soundOn = ref.watch(soundNotifierProvider);

            return ListTile(
              leading: Icon(
                soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: const Color(0xFF0B6B3A),
              ),
              title: Text(
                soundOn ? 'Sound On' : 'Sound Off',
                style: const TextStyle(
                  color: Color(0xFF0B6B3A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Switch.adaptive(
                value: soundOn,
                activeColor: const Color(0xFF0B6B3A),
                onChanged: (value) async {
                  await ref.read(soundNotifierProvider.notifier).toggle();
                },
              ),
            );
          },
        ),

        // inside _buildMainMenuItems
        ListTile(
          leading: const Icon(Icons.favorite_border, color: Colors.red),
          title: const Text(
            'Invite Friends',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            // 🔹 Close drawer first
            Navigator.pop(context);

            // 🔹 Share app message
            Share.share(
              'Peace be upon you, I just played "The Quran Quiz". '
              'Check it out and join me: https://www.flicksize.com/islamic_quiz/',
              subject: 'Join me in The Quran Quiz!',
            );
          },
        ),
      ],
    );
  }
}

class _DrawerUserSection extends StatelessWidget {
  const _DrawerUserSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final prefs = snap.data!;
        final phone = prefs.getString('userPhone')?.trim() ?? '';
        final userId = phone.replaceAll(RegExp(r'[^0-9]'), '');

        // If phone login exists, show Firestore-backed card; otherwise fallback to
        // the existing FirebaseAuth-based card.
        if (phone.isEmpty) {
          return const UserProfileCard();
        }

        // Migrate old prefs userId -> phone docId (best effort).
        if (prefs.getString('userId') != userId) {
          prefs.setString('userId', userId);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, userSnap) {
            final data = userSnap.data?.data() ?? <String, dynamic>{};
            final profileCompleted = data['profileCompleted'] == true;

            final name =
                (data['name'] ?? 'Unknown User').toString().trim().isEmpty
                ? 'Unknown User'
                : (data['name'] ?? 'Unknown User').toString();
            final email = (data['email'] ?? '').toString().trim();
            final base64Image = (data['profileImageBase64'] ?? '')
                .toString()
                .trim();

            ImageProvider? avatarProvider;
            if (base64Image.isNotEmpty) {
              try {
                avatarProvider = MemoryImage(base64Decode(base64Image));
              } catch (_) {
                avatarProvider = null;
              }
            }

            return InkWell(
              onTap: () {
                Navigator.pop(context); // close drawer first
                if (profileCompleted) {
                  AppRouter.router.push(AppRouter.profile);
                  return;
                }

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
                          colors: [Color(0xFF0B6B3A), Color(0xFF1B9C5A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: avatarProvider != null
                            ? Image(
                                image: avatarProvider,
                                fit: BoxFit.cover,
                                width: 54,
                                height: 54,
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
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
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.35),
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
                            email.isNotEmpty ? email : phone,
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
                      profileCompleted ? Icons.chevron_right : Icons.edit,
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
  }
}
