import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/presentation/auth/forgotten_password.dart';
import 'package:quiz_app/presentation/auth/signup.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/presentation/widgets/grid_background.dart';

final obscureTextProvider = StateProvider<bool>((ref) => true);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final loginErrorProvider = StateProvider<String?>((ref) => null);

final emailControllerProvider = Provider((ref) => TextEditingController());
final passwordControllerProvider = Provider((ref) => TextEditingController());

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _signIn() async {
    // Prevent double-taps causing multiple auth attempts.
    if (ref.read(isLoadingProvider)) return;

    final email = ref.read(emailControllerProvider).text.trim();
    final pass = ref.read(passwordControllerProvider).text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ref.read(loginErrorProvider.notifier).state = 'সব ফিল্ড পূরণ করুন';
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(loginErrorProvider.notifier).state = null;

    try {
      // Sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;
      if (user == null) throw Exception('লগইন ব্যর্থ হয়েছে');

      // Ensure this user has a profile in Firestore.
      // Prefer users/{uid}, but older data may have a different docId.
      final usersCol = _firestore.collection('users');

      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await usersCol.doc(user.uid).get();

      if (!userDoc.exists) {
        // Fallback: find legacy profile by stored uid field.
        // NOTE: This requires Firestore rules to allow reading a user doc
        // whose resource.data.uid == request.auth.uid (see rules update below).
        final snapByUid =
            await usersCol.where('uid', isEqualTo: user.uid).limit(1).get();

        final legacyDoc = snapByUid.docs.isNotEmpty ? snapByUid.docs.first : null;

        if (legacyDoc != null) {
          // Migrate/ensure canonical doc id == uid for rules & easy access
          final legacyData = legacyDoc.data();
          await usersCol.doc(user.uid).set(
            {
              ...legacyData,
              'uid': user.uid,
              'email': legacyData['email'] ?? email,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          userDoc = await usersCol.doc(user.uid).get();
        }
      }

      if (!userDoc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-profile-missing',
          message:
              'আপনার প্রোফাইল ডেটা পাওয়া যায়নি (users collection)। অনুগ্রহ করে সাইন আপ করুন।',
        );
      }

      if (!mounted) return;
      // Use the widget context's router to navigate reliably.
      context.go(AppRouter.home);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'এই ইমেইল দিয়ে কোনো ইউজার পাওয়া যায়নি';
          break;
        case 'wrong-password':
          msg = 'পাসওয়ার্ড ভুল';
          break;
        case 'invalid-email':
          msg = 'ইমেইল ফরম্যাট সঠিক নয়';
          break;
        case 'user-disabled':
          msg = 'এই অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে';
          break;
        case 'user-profile-missing':
          msg = e.message ??
              'আপনার প্রোফাইল ডেটা পাওয়া যায়নি (users collection)';
          break;
        default:
          msg = e.message ?? 'লগইন ব্যর্থ হয়েছে';
      }
      ref.read(loginErrorProvider.notifier).state = msg;
    } catch (e) {
      ref.read(loginErrorProvider.notifier).state = 'Error: $e';
    } finally {
      if (mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final obscure = ref.watch(obscureTextProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(loginErrorProvider);

    final emailCtrl = ref.watch(emailControllerProvider);
    final passCtrl = ref.watch(passwordControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GridBackground(),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      Text(
                            'Quiz Master',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B6B3A),
                                  letterSpacing: 1.2,
                                ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 800.ms)
                          .slideY(begin: -0.4),

                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your journey',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 48),

                      Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromRGBO(255, 255, 255, 0.9),
                                  Color.fromRGBO(255, 255, 255, 0.7),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(
                                  controller: emailCtrl,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: passCtrl,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: obscure,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF0B6B3A),
                                    ),
                                    onPressed: () =>
                                        ref
                                                .read(
                                                  obscureTextProvider.notifier,
                                                )
                                                .state =
                                            !obscure,
                                  ),
                                ),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      error,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B6B3A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ).animate().scale(curve: Curves.easeOutBack),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF0B6B3A),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          AppRouter.router.go(AppRouter.signup),
                                      child: const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Color(0xFF0B6B3A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 900.ms)
                          .slideY(begin: 0.3)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: const Color(0xFF0B6B3A).withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0B6B3A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    ref.read(emailControllerProvider).dispose();
    ref.read(passwordControllerProvider).dispose();
    super.dispose();
  }
}

// GridBackground remains the same (already shared)
