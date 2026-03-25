import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/presentation/widgets/grid_background.dart';

final signUpObscureProvider = StateProvider<bool>((ref) => true);
final signUpObscureConfirmProvider = StateProvider<bool>((ref) => true);
final signUpLoadingProvider = StateProvider<bool>((ref) => false);
final signUpErrorProvider = StateProvider<String?>((ref) => null);
final profileImageProvider = StateProvider<File?>((ref) => null);

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // Controllers – no provider dependency
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 720,
      maxHeight: 720,
    );

    if (picked != null && mounted) {
      ref.read(profileImageProvider.notifier).state = File(picked.path);
    }
  }

  Future<String?> _toBase64(File? file) async {
    if (file == null) return null;
    try {
      return base64Encode(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final imageFile = ref.read(profileImageProvider);

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      ref.read(signUpErrorProvider.notifier).state = 'সব ফিল্ড পূরণ করুন';
      return;
    }
    if (pass != confirm) {
      ref.read(signUpErrorProvider.notifier).state = 'পাসওয়ার্ড মিলছে না';
      return;
    }
    if (pass.length < 6) {
      ref.read(signUpErrorProvider.notifier).state =
          'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
      return;
    }

    ref.read(signUpLoadingProvider.notifier).state = true;
    ref.read(signUpErrorProvider.notifier).state = null;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;
      if (user == null) throw Exception('User creation failed');

      final base64Image = await _toBase64(imageFile);

      await user.updateDisplayName(name);

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'profileImageBase64': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // ─── Safe SnackBar & Navigation ───────────────────────────────
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'অ্যাকাউন্ট তৈরি হয়েছে!\nইমেইল ভেরিফিকেশন লিঙ্ক পাঠানো হয়েছে।',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Give time for SnackBar to show + ensure mounted
      await Future.delayed(const Duration(milliseconds: 1400));

      if (mounted) {
        AppRouter.router.go(AppRouter.login);
      }
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'email-already-in-use' => 'এই ইমেইলটি ইতিমধ্যে ব্যবহৃত',
        'invalid-email' => 'ইমেইল ফরম্যাট সঠিক নয়',
        'weak-password' => 'পাসওয়ার্ড খুব দুর্বল',
        _ => e.message ?? 'কিছু একটা সমস্যা হয়েছে',
      };
      if (mounted) {
        ref.read(signUpErrorProvider.notifier).state = msg;
      }
    } catch (e) {
      if (mounted) {
        ref.read(signUpErrorProvider.notifier).state = 'Error: $e';
      }
    } finally {
      if (mounted) {
        ref.read(signUpLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final obscure = ref.watch(signUpObscureProvider);
    final obscureConfirm = ref.watch(signUpObscureConfirmProvider);
    final isLoading = ref.watch(signUpLoadingProvider);
    final errorMsg = ref.watch(signUpErrorProvider);
    final profileImg = ref.watch(profileImageProvider);

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
                        'Join Quiz Master',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0B6B3A),
                              letterSpacing: 1.2,
                            ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.4),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account and start learning',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),

                      // Profile picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(
                                0xFF0B6B3A,
                              ).withOpacity(0.15),
                              backgroundImage: profileImg != null
                                  ? FileImage(profileImg)
                                  : null,
                              child: profileImg == null
                                  ? const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 50,
                                      color: Color(0xFF0B6B3A),
                                    )
                                  : null,
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF0B6B3A),
                              child: const Icon(
                                Icons.add_a_photo,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(
                        delay: 800.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 40),

                      // Form container
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildField(
                              _nameController,
                              'Full Name',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              _emailController,
                              'Email',
                              Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              _passwordController,
                              'Password',
                              Icons.lock_outline,
                              obscure: obscure,
                              suffix: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF0B6B3A),
                                ),
                                onPressed: () =>
                                    ref
                                            .read(
                                              signUpObscureProvider.notifier,
                                            )
                                            .state =
                                        !obscure,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              _confirmController,
                              'Confirm Password',
                              Icons.lock_outline,
                              obscure: obscureConfirm,
                              suffix: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF0B6B3A),
                                ),
                                onPressed: () =>
                                    ref
                                            .read(
                                              signUpObscureConfirmProvider
                                                  .notifier,
                                            )
                                            .state =
                                        !obscureConfirm,
                              ),
                            ),
                            if (errorMsg != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Text(
                                  errorMsg,
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
                                onPressed: isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B6B3A),
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
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ).animate().scale(curve: Curves.easeOutBack),
                            const SizedBox(height: 20),
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    AppRouter.router.go(AppRouter.login),
                                child: const Text(
                                  'Already have an account? Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF0B6B3A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon:
            Icon(icon, color: const Color(0xFF0B6B3A).withOpacity(0.7)),
        suffixIcon: suffix,
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
}
