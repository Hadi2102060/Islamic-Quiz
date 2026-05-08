import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/data/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/presentation/router/app_router.dart';

class UserProfileCard extends ConsumerWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    return authAsync.when(
      data: (User? user) {
        if (user == null) {
          return _buildGuestCard(context);
        }
        return _buildFirestoreUserCard(user.uid, context);
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, stack) => Center(child: Text('Auth error: $err')),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go(AppRouter.login),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF0B6B3A),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sign in to save progress',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRouter.login),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirestoreUserCard(String uid, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError) {
          return Text('Error loading profile: ${snapshot.error}');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('User data not found in Firestore');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final name = data['name'] as String? ?? 'User';
        final email = data['email'] as String? ?? 'No email';
        final base64Image = data['profileImageBase64'] as String?;

        Widget avatar;

        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(base64Image);
            avatar = CircleAvatar(
              radius: 28,
              backgroundImage: MemoryImage(bytes),
            );
          } catch (e) {
            // fallback if base64 invalid
            avatar = _buildInitialAvatar(name);
          }
        } else {
          avatar = _buildInitialAvatar(name);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => AppRouter.router.push(AppRouter.profile),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Avatar
                  avatar,
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Logout button
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Sign out',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  CircleAvatar _buildInitialAvatar(String name) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFF0B6B3A),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
