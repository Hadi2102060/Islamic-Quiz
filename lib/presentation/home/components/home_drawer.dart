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

                    const UserProfileCard(),

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

        ListTile(
          leading: const Icon(
            Icons.language_outlined,
            color: Color(0xFF0B6B3A),
          ),
          title: Text(
            AppLocalizations.of(context)!.languages,
            style: const TextStyle(
              color: Color(0xFF0B6B3A),
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context); // drawer বন্ধ করো
            showLanguageSelector(context, ref);
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
              'Check it out and join me: https://example.com/app_link',
              subject: 'Join me in The Quran Quiz!',
            );
          },
        ),
      ],
    );
  }
}
