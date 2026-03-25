import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/presentation/auth/login.dart';
import 'package:quiz_app/presentation/widgets/grid_background.dart';

// Providers
final forgotLoadingProvider = StateProvider<bool>((ref) => false);
final forgotErrorProvider = StateProvider<String?>((ref) => null);
final forgotEmailControllerProvider = Provider(
  (ref) => TextEditingController(),
);

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(forgotLoadingProvider);
    final error = ref.watch(forgotErrorProvider);
    final emailCtrl = ref.watch(forgotEmailControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          GridBackground(),

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
                      const SizedBox(height: 60),

                      Icon(
                            Icons.lock_reset_rounded,
                            size: 80,
                            color: const Color(0xFF0B6B3A),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .scale(curve: Curves.easeOutBack),

                      const SizedBox(height: 24),

                      Text(
                            'Reset Password',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B6B3A),
                                ),
                          )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .slideY(begin: -0.3, end: 0),

                      const SizedBox(height: 12),
                      Text(
                        'Enter your email to receive a reset link',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 700.ms),

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
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF0B6B3A),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0B6B3A),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        ref
                                                .read(
                                                  forgotLoadingProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;
                                        ref
                                                .read(
                                                  forgotErrorProvider.notifier,
                                                )
                                                .state =
                                            null;

                                        await Future.delayed(
                                          const Duration(seconds: 2),
                                        );

                                        if (emailCtrl.text.trim().isEmpty) {
                                          ref
                                                  .read(
                                                    forgotErrorProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              'Please enter your email';
                                        } else {
                                          // Simulate send email
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Reset link sent! Check your email.',
                                                ),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        }

                                        if (context.mounted) {
                                          ref
                                                  .read(
                                                    forgotLoadingProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false;
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0B6B3A),
                                  foregroundColor: Colors.white,
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
                                        'Send Reset Link',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Back to Sign In',
                                style: TextStyle(color: Color(0xFF0B6B3A)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3, end: 0),
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
}
