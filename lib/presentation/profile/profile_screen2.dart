import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePageScreen2 extends StatefulWidget {
  const ProfilePageScreen2({super.key});

  @override
  State<ProfilePageScreen2> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfilePageScreen2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // User data
  String _userId = '';
  String _userName = '';
  String _userEmail = '';
  String _userLevel = 'Level 1';
  String _userTitle = 'Beginner';
  String? _profileImageBase64;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _authMethod = '';
  bool _isProfileCompleted = false;
  String _userPhone = '';

  // User statistics
  int _totalQuizzes = 0;
  int _totalWins = 0;
  double _accuracy = 0.0;

  // For tracking real-time subscription
  StreamSubscription<DocumentSnapshot>? _leaderboardSubscription;

  static const String _forceOtpPhoneKey = 'forceOtpPhone';

  String? _phoneDigitsFromDeterministicEmail(User user) {
    final email = (user.email ?? '').trim().toLowerCase();
    const suffix = '@islamic-quiz.local';
    if (!email.endsWith(suffix)) return null;
    final digits = email.substring(0, email.length - suffix.length);
    if (RegExp(r'^01[0-9]{9}$').hasMatch(digits)) return digits;
    return null;
  }

  Future<void> _syncUserPublicFieldsFromProfile() async {
    if (_userId.isEmpty) return;
    final name = _userName.isNotEmpty ? _userName : 'Unknown User';
    try {
      await _firestore.collection('leaderboard').doc(_userId).set({
        'userName': name,
        'lastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    try {
      final snap = await _firestore
          .collection('results')
          .where('userId', isEqualTo: _userId)
          .limit(500)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        final payload = <String, dynamic>{'userName': name};
        if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
          payload['profileImageBase64'] = _profileImageBase64;
        }
        batch.set(d.reference, payload, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Subscribe to real-time leaderboard updates for the user
  void _subscribeToLeaderboardUpdates() {
    if (_userId.isEmpty) return;

    _leaderboardSubscription?.cancel();

    _leaderboardSubscription = _firestore
        .collection('leaderboard')
        .doc(_userId)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists && mounted) {
              final data = snapshot.data() as Map<String, dynamic>;

              final quizzesPlayed = data['quizzesPlayed'] ?? 0;
              final totalScore = data['totalScore'] ?? 0;

              setState(() {
                _totalQuizzes = quizzesPlayed;

                if (quizzesPlayed > 0) {
                  _accuracy = (totalScore / (quizzesPlayed * 100)) * 100;
                  _accuracy = _accuracy.clamp(0.0, 100.0);
                } else {
                  _accuracy = 0.0;
                }

                _totalWins =
                    data['totalWins'] ??
                    _calculateWinsFromScore(totalScore, quizzesPlayed);

                if (data['userName'] != null && data['userName'] != _userName) {
                  _userName = data['userName'];
                }

                _updateLevelAndTitle(quizzesPlayed, _accuracy);
              });
            }
          },
          onError: (error) {
            print('Error listening to leaderboard updates: $error');
          },
        );
  }

  int _calculateWinsFromScore(int totalScore, int quizzesPlayed) {
    if (quizzesPlayed == 0) return 0;
    return (totalScore / (quizzesPlayed * 100) * quizzesPlayed * 0.7).round();
  }

  void _updateLevelAndTitle(int quizzesPlayed, double accuracy) {
    if (quizzesPlayed == 0) {
      _userLevel = 'Level 1';
      _userTitle = 'Beginner';
      return;
    }

    if (quizzesPlayed >= 100) {
      _userLevel = 'Level 5';
      _userTitle = 'Master';
    } else if (quizzesPlayed >= 50) {
      _userLevel = 'Level 4';
      _userTitle = 'Expert';
    } else if (quizzesPlayed >= 20) {
      _userLevel = 'Level 3';
      _userTitle = 'Advanced';
    } else if (quizzesPlayed >= 10) {
      _userLevel = 'Level 2';
      _userTitle = 'Intermediate';
    } else {
      _userLevel = 'Level 1';
      _userTitle = 'Beginner';
    }

    if (accuracy >= 90) {
      _userTitle = 'Scholar';
    } else if (accuracy >= 80) {
      _userTitle = _userTitle == 'Master' ? 'Grand Master' : _userTitle;
    } else if (accuracy >= 70) {
      _userTitle = _userTitle == 'Expert' ? 'Senior Expert' : _userTitle;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    _leaderboardSubscription?.cancel();
    super.dispose();
  }

  void _checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('userPhone');
    final savedUserId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = _auth.currentUser != null || savedPhone != null;
      if (savedPhone != null && savedPhone.trim().isNotEmpty) {
        _userPhone = savedPhone;
        _userId = savedPhone.replaceAll(RegExp(r'[^0-9]'), '');
      }
      final cu = _auth.currentUser;
      if (cu != null) {
        final phoneDigits = _phoneDigitsFromDeterministicEmail(cu);
        if (phoneDigits != null) {
          _userId = phoneDigits;
          _userPhone = phoneDigits;
        } else if (savedUserId != null && savedUserId.trim().isNotEmpty) {
          _userId = savedUserId.trim();
        }
      }
    });

    if (_isLoggedIn) {
      await _loadUserData();
      _subscribeToLeaderboardUpdates();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('userPhone');
      final savedUserId = prefs.getString('userId');

      final phoneDocId = (() {
        if (savedPhone != null && savedPhone.trim().isNotEmpty) {
          return savedPhone.replaceAll(RegExp(r'[^0-9]'), '');
        }
        if (currentUser != null)
          return _phoneDigitsFromDeterministicEmail(currentUser);
        return null;
      })();

      if (phoneDocId != null && phoneDocId.isNotEmpty) {
        _userId = phoneDocId;
        _authMethod = 'phone';
        _userPhone = phoneDocId;

        final userDoc = await _firestore
            .collection('users')
            .doc(phoneDocId)
            .get();

        final leaderboardDoc = await _firestore
            .collection('leaderboard')
            .doc(phoneDocId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _userName = (userData['name'] ?? 'Unknown User').toString();
            _userEmail = (userData['email'] ?? '').toString();
            _profileImageBase64 = userData['profileImageBase64'];
            _authMethod = userData['authMethod'] ?? 'phone';
            _isProfileCompleted = userData['profileCompleted'] ?? false;
            _userPhone = (userData['phoneNumber'] ?? phoneDocId).toString();
          });
        } else {
          await _firestore.collection('users').doc(phoneDocId).set({
            'uid': currentUser?.uid,
            'phoneNumber': phoneDocId,
            'authMethod': 'phone',
            'name': 'Unknown User',
            'profileCompleted': false,
            'isSkipped': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          setState(() {
            _userName = 'Unknown User';
            _userEmail = '';
            _authMethod = 'phone';
            _isProfileCompleted = false;
          });
        }

        if (leaderboardDoc.exists) {
          final leaderboardData = leaderboardDoc.data() as Map<String, dynamic>;
          final quizzesPlayed = leaderboardData['quizzesPlayed'] ?? 0;
          final totalScore = leaderboardData['totalScore'] ?? 0;

          setState(() {
            _totalQuizzes = quizzesPlayed;
            if (quizzesPlayed > 0) {
              _accuracy = (totalScore / (quizzesPlayed * 100)) * 100;
              _accuracy = _accuracy.clamp(0.0, 100.0);
            } else {
              _accuracy = 0.0;
            }
            _totalWins = leaderboardData['totalWins'] ?? 0;
          });

          _updateLevelAndTitle(_totalQuizzes, _accuracy);
        }
      } else if (currentUser != null) {
        _userId = currentUser.uid;

        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        DocumentSnapshot leaderboardDoc;
        if (_userPhone.isNotEmpty) {
          leaderboardDoc = await _firestore
              .collection('leaderboard')
              .doc(_userPhone.replaceAll(RegExp(r'[^0-9]'), ''))
              .get();
          if (!leaderboardDoc.exists) {
            leaderboardDoc = await _firestore
                .collection('leaderboard')
                .doc(currentUser.uid)
                .get();
          }
        } else {
          leaderboardDoc = await _firestore
              .collection('leaderboard')
              .doc(currentUser.uid)
              .get();
        }

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? currentUser.displayName ?? 'User';
            _userEmail = userData['email'] ?? currentUser.email ?? '';
            _profileImageBase64 = userData['profileImageBase64'];
            _authMethod =
                userData['authMethod'] ??
                (userData['email'] != null ? 'email' : 'phone');
            _isProfileCompleted = userData['profileCompleted'] ?? false;
            _userPhone = userData['phoneNumber'] ?? savedPhone ?? '';
          });
        } else {
          if (savedPhone != null) {
            await _createPhoneUserDocument(currentUser, savedPhone);
          } else {
            await _createUserDocument(currentUser);
          }
        }

        if (leaderboardDoc.exists) {
          final leaderboardData = leaderboardDoc.data() as Map<String, dynamic>;
          final quizzesPlayed = leaderboardData['quizzesPlayed'] ?? 0;
          final totalScore = leaderboardData['totalScore'] ?? 0;

          setState(() {
            _totalQuizzes = quizzesPlayed;
            if (quizzesPlayed > 0) {
              _accuracy = (totalScore / (quizzesPlayed * 100)) * 100;
              _accuracy = _accuracy.clamp(0.0, 100.0);
            } else {
              _accuracy = 0.0;
            }
            _totalWins = leaderboardData['totalWins'] ?? 0;
          });

          _updateLevelAndTitle(_totalQuizzes, _accuracy);
        }
      } else if (savedPhone != null) {
        setState(() {
          _userId = savedUserId ?? savedPhone.replaceAll(RegExp(r'[^0-9]'), '');
          _userName = 'User ${savedPhone.substring(savedPhone.length - 4)}';
          _userEmail = '';
          _authMethod = 'phone';
          _isProfileCompleted = false;
          _userPhone = savedPhone;
        });

        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(_userId)
              .get();

          DocumentSnapshot leaderboardDoc = await _firestore
              .collection('leaderboard')
              .doc(_userId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            setState(() {
              _userName = userData['name'] ?? _userName;
              _userEmail = userData['email'] ?? '';
              _profileImageBase64 = userData['profileImageBase64'];
              _isProfileCompleted = userData['profileCompleted'] ?? false;
            });
          }

          if (leaderboardDoc.exists) {
            Map<String, dynamic> leaderboardData =
                leaderboardDoc.data() as Map<String, dynamic>;
            final quizzesPlayed = leaderboardData['quizzesPlayed'] ?? 0;
            final totalScore = leaderboardData['totalScore'] ?? 0;

            setState(() {
              _totalQuizzes = quizzesPlayed;
              if (quizzesPlayed > 0) {
                _accuracy = (totalScore / (quizzesPlayed * 100)) * 100;
                _accuracy = _accuracy.clamp(0.0, 100.0);
              } else {
                _accuracy = 0.0;
              }
              _totalWins = leaderboardData['totalWins'] ?? 0;
            });

            _updateLevelAndTitle(_totalQuizzes, _accuracy);
          }
        } catch (e) {
          print('Error loading Firestore data: $e');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'profileImageBase64': null,
        'level': 'Level 1',
        'title': 'Beginner',
        'totalQuizzes': 0,
        'totalWins': 0,
        'accuracy': 0.0,
        'points': 0,
        'rank': 'Beginner',
        'authMethod': 'email',
        'profileCompleted': user.displayName != null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userName = user.displayName ?? 'User';
        _userEmail = user.email ?? '';
        _authMethod = 'email';
        _isProfileCompleted = user.displayName != null;
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _createPhoneUserDocument(User user, String phoneNumber) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': 'User ${phoneNumber.substring(phoneNumber.length - 4)}',
        'email': null,
        'phoneNumber': phoneNumber,
        'profileImageBase64': null,
        'level': 'Level 1',
        'title': 'Beginner',
        'totalQuizzes': 0,
        'totalWins': 0,
        'accuracy': 0.0,
        'points': 0,
        'rank': 'Beginner',
        'authMethod': 'phone',
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userName = 'User ${phoneNumber.substring(phoneNumber.length - 4)}';
        _userEmail = '';
        _authMethod = 'phone';
        _isProfileCompleted = false;
        _userPhone = phoneNumber;
      });
    } catch (e) {
      print('Error creating phone user document: $e');
    }
  }

  Future<void> _pickImage() async {
    if (!_isLoggedIn) {
      _showLoginRequiredSnackbar('Please login to update profile picture');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        File imageFile = File(image.path);
        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        await _firestore.collection('users').doc(_userId).update({
          'profileImageBase64': base64Image,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _profileImageBase64 = base64Image;
          _isLoading = false;
        });

        await _syncUserPublicFieldsFromProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<http.Response> _postWithJsonFallback(
    String endpoint,
    Map<String, String> payload,
  ) async {
    final uri = Uri.parse('https://www.flicksize.com/islamic_quiz/$endpoint');
    final formResponse = await http.post(uri, body: payload);
    final bodyLower = formResponse.body.toLowerCase();
    final requiresJson =
        bodyLower.contains('invalid json payload') ||
        bodyLower.contains('malformed json') ||
        bodyLower.contains('expected json');

    if (!requiresJson) return formResponse;

    return http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );
  }

  bool _isUnsubscribeApiSuccess(
    Map<String, dynamic> data,
    String rawBody,
    int statusCode,
  ) {
    final success = data['success'] == true;
    final apiStatusCode = (data['statusCode'] ?? '').toString().toUpperCase();
    final status = (data['status'] ?? '').toString().toUpperCase();
    final message = (data['message'] ?? '').toString().toLowerCase();
    final statusDetail = (data['statusDetail'] ?? '').toString().toLowerCase();
    final raw = rawBody.trim().toLowerCase();

    final hasFailureWord =
        raw.contains('error') ||
        raw.contains('failed') ||
        raw.contains('invalid') ||
        message.contains('error') ||
        message.contains('failed') ||
        message.contains('invalid');

    final plainTextSuccess =
        raw == '1' ||
        raw == 'ok' ||
        raw == 'success' ||
        raw == 'true' ||
        raw.contains('unsubscribe successful') ||
        raw.contains('unsubscription is successful') ||
        raw.contains('already unsubscribed') ||
        raw.contains('removed');

    return success ||
        apiStatusCode.startsWith('S') ||
        status == 'SUCCESS' ||
        message.contains('unsubscription is successful') ||
        message.contains('unsubscribe successful') ||
        message.contains('already unsubscribed') ||
        // Key fix: statusDetail with 'un-registered' means actually unregistered
        statusDetail.contains('un-registered') ||
        statusDetail.contains('unregistered') ||
        plainTextSuccess ||
        (statusCode == 200 && raw.isNotEmpty && !hasFailureWord);
  }

  Future<void> _handleUnsubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = (prefs.getString('userPhone') ?? _userPhone).trim();
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No phone number found')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      http.Response? resp;
      for (final endpoint in const ['unsubscribe.php', 'unsubscription.php']) {
        final candidate = await _postWithJsonFallback(endpoint, {
          'user_mobile': phone,
        }).timeout(const Duration(seconds: 15));
        if (candidate.statusCode == 200) {
          resp = candidate;
          break;
        }
      }
      if (resp == null) {
        throw Exception('Unsubscribe endpoint not reachable');
      }

      Map<String, dynamic> parsed = {};
      String message = 'Unsubscription successful. Please login again.';

      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          parsed = decoded;
          final statusDetail = (decoded['statusDetail'] ?? '')
              .toString()
              .toLowerCase();

          // If statusDetail says un-registered, treat as successful even if API says failed
          if (statusDetail.contains('un-registered') ||
              statusDetail.contains('unregistered')) {
            message = 'Successfully unsubscribed. Please login again with OTP.';
          } else if ((decoded['message'] ?? '').toString().trim().isNotEmpty) {
            message = decoded['message'].toString();
          }
          print('📡 Unsubscribe response: $decoded');
        }
      } catch (_) {}

      final ok = _isUnsubscribeApiSuccess(parsed, resp.body, resp.statusCode);
      if (!ok) {
        throw Exception(
          message == 'Unsubscription successful. Please login again.'
              ? 'Unsubscribe request failed'
              : message,
        );
      }

      await prefs.setString(_forceOtpPhoneKey, phone);

      await prefs.remove('isLoggedIn');
      await prefs.remove('userPhone');
      await prefs.remove('userId');

      await _auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      context.go(AppRouter.login);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unsubscribe failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _showLoginRequiredSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            context.go(AppRouter.login);
          },
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    if (!_isLoggedIn) {
      _showLoginRequiredSnackbar('Please login to edit your name');
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: _userName,
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A2A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Name',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber),
              ),
              filled: true,
              fillColor: Colors.white12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  setState(() => _isLoading = true);

                  try {
                    await _firestore.collection('users').doc(_userId).update({
                      'name': controller.text,
                      'profileCompleted': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    await _firestore
                        .collection('leaderboard')
                        .doc(_userId)
                        .update({
                          'userName': controller.text,
                          'lastPlayed': FieldValue.serverTimestamp(),
                        });

                    setState(() {
                      _userName = controller.text;
                      _isProfileCompleted = true;
                      _isLoading = false;
                    });

                    await _syncUserPublicFieldsFromProfile();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Name updated successfully!'),
                          backgroundColor: Colors.green.shade800,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating name: $e'),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToProfileCompletion() async {
    context.go(AppRouter.profileComplete);
  }

  Future<void> _navigateToUserDetails() async {
    if (!_isLoggedIn) {
      _showLoginRequiredSnackbar('Please login to view user details');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(
          userId: _userId,
          userName: _userName,
          userEmail: _userEmail,
          userLevel: _userLevel,
          userTitle: _userTitle,
          profileImageBase64: _profileImageBase64,
          userPhone: _userPhone,
          authMethod: _authMethod,
          isProfileCompleted: _isProfileCompleted,
          totalQuizzes: _totalQuizzes,
          totalWins: _totalWins,
          accuracy: _accuracy,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF071B2F),
                  Color(0xFF073E3A),
                  Color(0xFF0A4D4A),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Decorative Lottie
          Positioned(
            right: -20,
            top: -10,
            child: Opacity(
              opacity: 0.08,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(
                  'assets/lottie_files/Islamic_shape.json',
                  repeat: true,
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with back button
                      Row(
                        children: [
                          Material(
                            color: Colors.white12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.of(context).maybePop(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ).animate().scale(
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                                child: Text(
                                  'Profile',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 100.ms)
                              .slideX(begin: -0.2, end: 0),
                          if (_isLoggedIn)
                            Material(
                              color: Colors.white12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: _navigateToUserDetails,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ).animate().scale(delay: 200.ms),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Avatar + name section
                      GestureDetector(
                        onTap: _isLoggedIn
                            ? _navigateToProfileCompletion
                            : null,
                        child: Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white12,
                                      backgroundImage:
                                          _profileImageBase64 != null &&
                                              _isLoggedIn
                                          ? MemoryImage(
                                                  base64Decode(
                                                    _profileImageBase64!,
                                                  ),
                                                )
                                                as ImageProvider
                                          : null,
                                      child:
                                          !_isLoggedIn ||
                                              _profileImageBase64 == null
                                          ? Icon(
                                              _isLoggedIn
                                                  ? Icons.person
                                                  : Icons.account_circle,
                                              color: Colors.white54,
                                              size: 40,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (_isLoggedIn)
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.amber.shade600,
                                              Colors.amber.shade800,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(
                                                0.4,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera,
                                          color: Colors.black87,
                                          size: 20,
                                        ),
                                      ),
                                    ).animate().scale(
                                      delay: 200.ms,
                                      duration: 400.ms,
                                      curve: Curves.elasticOut,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _isLoggedIn ? _userName : 'Guest',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isLoggedIn &&
                                      _authMethod == 'email') ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showEditNameDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (_authMethod == 'phone' &&
                                  _userPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _userPhone,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (_isLoggedIn && _isProfileCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.withOpacity(0.2),
                                        Colors.teal.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    '$_userLevel • $_userTitle',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else if (_isLoggedIn && !_isProfileCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Profile Incomplete',
                                    style: GoogleFonts.inter(
                                      color: Colors.orange.shade300,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    'Not Signed In',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stat cards
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedProfileStatCard(
                              title: 'Quizzes',
                              value: _isLoggedIn ? '$_totalQuizzes' : '0',
                              icon: Icons.quiz,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                              ),
                              trend: _isLoggedIn && _totalQuizzes > 0
                                  ? '+$_totalQuizzes'
                                  : '0',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedProfileStatCard(
                              title: 'Wins',
                              value: _isLoggedIn ? '$_totalWins' : '0',
                              icon: Icons.emoji_events,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
                              ),
                              trend: _isLoggedIn && _totalQuizzes > 0
                                  ? '${((_totalWins / _totalQuizzes) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedProfileStatCard(
                              title: 'Accuracy',
                              value: _isLoggedIn
                                  ? '${_accuracy.toStringAsFixed(1)}%'
                                  : '0%',
                              icon: Icons.analytics,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                              ),
                              trend: _isLoggedIn
                                  ? '+${_accuracy.toStringAsFixed(0)}%'
                                  : '0%',
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      if (_isLoggedIn &&
                          !_isProfileCompleted &&
                          _authMethod == 'phone') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.15),
                                Colors.orange.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1,
                                    color: Colors.amber.shade300,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Complete Your Profile',
                                    style: GoogleFonts.inter(
                                      color: Colors.amber.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your name and email to get personalized experience',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _navigateToProfileCompletion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Complete Profile Now'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_isLoggedIn && _isProfileCompleted)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.military_tech,
                                      color: Colors.amber.shade200,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Achievements',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                height: 80,
                                child: _userId.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Sign in to see achievements',
                                          style: GoogleFonts.inter(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      )
                                    : StreamBuilder<QuerySnapshot>(
                                        // Use public `results` collection so anonymous users (with phone-only login)
                                        // can still read recent results / derive achievements under your Firestore rules.
                                        stream: _firestore
                                            .collection('results')
                                            .where('userId', isEqualTo: _userId)
                                            .limit(50)
                                            .snapshots(),
                                        builder: (context, snap) {
                                          if (snap.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error loading achievements',
                                                style: GoogleFonts.inter(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            );
                                          }
                                          if (!snap.hasData ||
                                              snap.data!.docs.isEmpty) {
                                            return Center(
                                              child: Text(
                                                'No achievements yet',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            );
                                          }

                                          // Sort client-side by updatedAt (avoid requiring composite index)
                                          final docs = [...snap.data!.docs];
                                          docs.sort((a, b) {
                                            final aData =
                                                a.data()
                                                    as Map<String, dynamic>;
                                            final bData =
                                                b.data()
                                                    as Map<String, dynamic>;
                                            final aTs =
                                                aData['updatedAt'] ??
                                                aData['timestamp'];
                                            final bTs =
                                                bData['updatedAt'] ??
                                                bData['timestamp'];
                                            final aDate = aTs is Timestamp
                                                ? aTs.toDate()
                                                : DateTime.tryParse(
                                                        aTs?.toString() ?? '',
                                                      ) ??
                                                      DateTime.fromMillisecondsSinceEpoch(
                                                        0,
                                                      );
                                            final bDate = bTs is Timestamp
                                                ? bTs.toDate()
                                                : DateTime.tryParse(
                                                        bTs?.toString() ?? '',
                                                      ) ??
                                                      DateTime.fromMillisecondsSinceEpoch(
                                                        0,
                                                      );
                                            return bDate.compareTo(aDate);
                                          });

                                          // Derive simple achievements from the most recent results
                                          final recent = docs.take(10).toList();
                                          final derived =
                                              <Map<String, dynamic>>[];
                                          for (final d in recent) {
                                            final m =
                                                d.data()
                                                    as Map<String, dynamic>;
                                            final pct =
                                                (m['percentage'] ??
                                                m['score'] ??
                                                0);
                                            final percentage = (pct is num)
                                                ? pct.toDouble()
                                                : double.tryParse(
                                                        pct.toString(),
                                                      ) ??
                                                      0.0;
                                            if (percentage >= 100) {
                                              derived.add({
                                                'name': 'Perfect Score',
                                                'type': 'perfect',
                                                'progress': 1.0,
                                              });
                                            } else if (percentage >= 80) {
                                              derived.add({
                                                'name': 'Top 80%',
                                                'type': 'top100',
                                                'progress': (percentage / 100)
                                                    .clamp(0.0, 1.0),
                                              });
                                            } else {
                                              derived.add({
                                                'name':
                                                    m['category'] ?? 'Played',
                                                'type': 'streak',
                                                'progress': (percentage / 100)
                                                    .clamp(0.0, 1.0),
                                              });
                                            }
                                          }

                                          return ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: derived.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 8),
                                            itemBuilder: (context, index) {
                                              final achievement =
                                                  derived[index];
                                              return AnimatedAchievementChip(
                                                label:
                                                    achievement['name'] ??
                                                    'Achievement',
                                                color: _getAchievementColor(
                                                  achievement['type'] ?? '',
                                                ),
                                                icon: _getAchievementIcon(
                                                  achievement['type'] ?? '',
                                                ),
                                                progress:
                                                    (achievement['progress'] ??
                                                            0.0)
                                                        .toDouble(),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),

                      if (_isLoggedIn && _isProfileCompleted)
                        const SizedBox(height: 16),

                      if (_isLoggedIn && _isProfileCompleted)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.history,
                                      color: Colors.teal.shade200,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recent Activity',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _userId.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Text(
                                          'Sign in to see recent activity',
                                          style: GoogleFonts.inter(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    )
                                  : StreamBuilder<QuerySnapshot>(
                                      // Use public `results` collection so anonymous users can see recent activity
                                      // Avoid server-side orderBy to prevent composite-index requirement.
                                      stream: _firestore
                                          .collection('results')
                                          .where('userId', isEqualTo: _userId)
                                          .limit(50)
                                          .snapshots(),
                                      builder: (context, snap) {
                                        if (snap.hasError)
                                          return Center(
                                            child: Text(
                                              'Error loading activities',
                                              style: GoogleFonts.inter(
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        if (!snap.hasData ||
                                            snap.data!.docs.isEmpty)
                                          return Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 20,
                                                  ),
                                              child: Text(
                                                'No recent activities',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                          );
                                        // Sort client-side by updatedAt to show most-recent first
                                        final docs = [...snap.data!.docs];
                                        docs.sort((a, b) {
                                          final aData =
                                              a.data() as Map<String, dynamic>;
                                          final bData =
                                              b.data() as Map<String, dynamic>;
                                          final aTs =
                                              aData['updatedAt'] ??
                                              aData['timestamp'];
                                          final bTs =
                                              bData['updatedAt'] ??
                                              bData['timestamp'];
                                          final aDate = aTs is Timestamp
                                              ? aTs.toDate()
                                              : DateTime.tryParse(
                                                      aTs?.toString() ?? '',
                                                    ) ??
                                                    DateTime.fromMillisecondsSinceEpoch(
                                                      0,
                                                    );
                                          final bDate = bTs is Timestamp
                                              ? bTs.toDate()
                                              : DateTime.tryParse(
                                                      bTs?.toString() ?? '',
                                                    ) ??
                                                    DateTime.fromMillisecondsSinceEpoch(
                                                      0,
                                                    );
                                          return bDate.compareTo(aDate);
                                        });

                                        final recent = docs.take(10).toList();

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: recent.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                color: Colors.white12,
                                                height: 1,
                                              ),
                                          itemBuilder: (context, index) {
                                            final result =
                                                recent[index].data()
                                                    as Map<String, dynamic>;
                                            final title =
                                                result['category'] ??
                                                result['categoryTitle'] ??
                                                'Quiz';
                                            final scoreVal =
                                                (result['percentage'] ??
                                                result['score'] ??
                                                0);
                                            final score = (scoreVal is num)
                                                ? scoreVal.toInt()
                                                : int.tryParse(
                                                        scoreVal.toString(),
                                                      ) ??
                                                      0;
                                            final ts =
                                                result['updatedAt'] ??
                                                result['updatedAt'] ??
                                                null;
                                            return AnimatedActivityTile(
                                              index: index,
                                              score: score,
                                              title: title,
                                              date: _formatDate(ts),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),

                      if (_isLoggedIn && _isProfileCompleted)
                        const SizedBox(height: 16),

                      if (_isLoggedIn && _isProfileCompleted)
                        AnimatedActionButton(
                          label: 'My Results',
                          icon: Icons.insights,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
                          ),
                          onPressed: () {
                            context.push(AppRouter.myResults);
                          },
                        ),

                      if (_isLoggedIn && _isProfileCompleted)
                        const SizedBox(height: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (_isLoggedIn && _authMethod == 'email')
                                Expanded(
                                  flex: 2,
                                  child: AnimatedActionButton(
                                    label: 'Edit Profile',
                                    icon: Icons.edit,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD54F),
                                        Color(0xFFFFA000),
                                      ],
                                    ),
                                    onPressed: _showEditNameDialog,
                                  ),
                                ),
                              if (_isLoggedIn && _authMethod == 'phone')
                                Expanded(
                                  flex: 2,
                                  child: AnimatedActionButton(
                                    label: _isProfileCompleted
                                        ? 'Edit Profile'
                                        : 'Complete Profile',
                                    icon: Icons.edit,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD54F),
                                        Color(0xFFFFA000),
                                      ],
                                    ),
                                    onPressed: _navigateToProfileCompletion,
                                  ),
                                ),

                              if (_isLoggedIn &&
                                  (_authMethod == 'email' ||
                                      _authMethod == 'phone'))
                                const SizedBox(width: 10),

                              Expanded(
                                flex: _isLoggedIn ? 1 : 3,
                                child: AnimatedActionButton(
                                  label: _isLoggedIn ? 'Logout' : 'Login',
                                  icon: _isLoggedIn
                                      ? Icons.logout
                                      : Icons.login,
                                  gradient: _isLoggedIn
                                      ? const LinearGradient(
                                          colors: [
                                            Colors.redAccent,
                                            Colors.red,
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.greenAccent,
                                          ],
                                        ),
                                  onPressed: _isLoggedIn
                                      ? () => _showLogoutDialog(context)
                                      : () => context.go(AppRouter.login),
                                ),
                              ),
                            ],
                          ),

                          if (_isLoggedIn) const SizedBox(height: 10),

                          if (_isLoggedIn)
                            Align(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 200,
                                child: AnimatedActionButton(
                                  label: 'Unsubscribe',
                                  icon: Icons.cancel_outlined,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFFC62828),
                                    ],
                                  ),
                                  onPressed: _confirmUnsubscribe,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (!_isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber.shade300,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You are browsing as guest',
                                  style: GoogleFonts.inter(
                                    color: Colors.amber.shade300,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Login to track your progress and earn achievements',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'top100':
        return Colors.amber;
      case 'fast':
        return Colors.greenAccent;
      case 'perfect':
        return Colors.purpleAccent;
      case 'streak':
        return Colors.blueAccent;
      default:
        return Colors.orange;
    }
  }

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'top100':
        return Icons.emoji_events;
      case 'fast':
        return Icons.speed;
      case 'perfect':
        return Icons.workspace_premium;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.school;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${(difference.inDays / 30).floor()} months ago';
      }
    }
    return 'Unknown';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A2A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                try {
                  _leaderboardSubscription?.cancel();

                  await _auth.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('userPhone');
                  await prefs.remove('userId');

                  if (mounted) {
                    setState(() {
                      _isLoggedIn = false;
                      _userId = '';
                      _userName = '';
                      _userEmail = '';
                      _userLevel = 'Level 1';
                      _userTitle = 'Beginner';
                      _profileImageBase64 = null;
                      _totalQuizzes = 0;
                      _totalWins = 0;
                      _accuracy = 0.0;
                      _authMethod = '';
                      _isProfileCompleted = false;
                      _userPhone = '';
                      _isLoading = false;
                    });
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              },
              child: Text(
                'Logout',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmUnsubscribe() async {
    if (!mounted) return;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A2A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Unsubscribe',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to unsubscribe?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (res == true) {
      await _handleUnsubscribe();
    }
  }
}

// AnimatedProfileStatCard widget
class AnimatedProfileStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final String trend;

  const AnimatedProfileStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.trend,
  });

  @override
  State<AnimatedProfileStatCard> createState() =>
      _AnimatedProfileStatCardState();
}

class _AnimatedProfileStatCardState extends State<AnimatedProfileStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.value,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.trend,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// AnimatedAchievementChip widget
class AnimatedAchievementChip extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double progress;

  const AnimatedAchievementChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.progress,
  });

  @override
  State<AnimatedAchievementChip> createState() =>
      _AnimatedAchievementChipState();
}

class _AnimatedAchievementChipState extends State<AnimatedAchievementChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color.withOpacity(0.2),
              widget.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.color.withOpacity(_isHovered ? 0.5 : 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 14),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AnimatedActivityTile widget
class AnimatedActivityTile extends StatefulWidget {
  final int index;
  final int score;
  final String title;
  final String date;

  const AnimatedActivityTile({
    super.key,
    required this.index,
    required this.score,
    required this.title,
    required this.date,
  });

  @override
  State<AnimatedActivityTile> createState() => _AnimatedActivityTileState();
}

class _AnimatedActivityTileState extends State<AnimatedActivityTile> {
  bool _isHovered = false;

  String? selectedCategory;
  final List<String> categories = [
    'Islamic Knowledge',
    'Quran and Hadith',
    'General Quiz',
    'Surahs Quiz',
    'Verses Quiz',
    'Prophets Quiz',
    'Seerah Quiz',
    'All Quiz',
  ];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getScoreColor().withOpacity(0.3),
                        _getScoreColor().withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getScoreColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Q${widget.index + 1}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.score}%',
                              style: GoogleFonts.inter(
                                color: _getScoreColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.date,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (mounted) {
                      Share.share(
                        'Peace be upon you, I just played "The Quran Quiz" in the $selectedCategory category. '
                        'Check it out and join me: https://example.com/app_link',
                        subject: 'Join me in The Quran Quiz!',
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isHovered ? Colors.white12 : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: (400 + widget.index * 100).ms)
        .slideX(begin: 0.2, end: 0);
  }

  Color _getScoreColor() {
    if (widget.score >= 90) return Colors.greenAccent;
    if (widget.score >= 70) return Colors.amber;
    return Colors.orange;
  }
}

// AnimatedActionButton widget
class AnimatedActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onPressed;

  const AnimatedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _isPressed
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: widget.label == 'Logout' || widget.label == 'Login'
                  ? Colors.white
                  : Colors.black87,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: widget.label == 'Logout' || widget.label == 'Login'
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Details Screen (Full Info Screen)
class UserDetailsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userLevel;
  final String userTitle;
  final String? profileImageBase64;
  final String userPhone;
  final String authMethod;
  final bool isProfileCompleted;
  final int totalQuizzes;
  final int totalWins;
  final double accuracy;

  const UserDetailsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userLevel,
    required this.userTitle,
    this.profileImageBase64,
    this.userPhone = '',
    this.authMethod = '',
    this.isProfileCompleted = false,
    this.totalQuizzes = 0,
    this.totalWins = 0,
    this.accuracy = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071B2F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'User not found',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white12,
                          backgroundImage: profileImageBase64 != null
                              ? MemoryImage(base64Decode(profileImageBase64!))
                                    as ImageProvider
                              : null,
                          child: profileImageBase64 == null
                              ? Text(
                                  _getInitials(userName),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 40,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person, 'Name', userName),
                      if (userEmail.isNotEmpty)
                        _buildInfoRow(Icons.email, 'Email', userEmail),
                      if (userPhone.isNotEmpty)
                        _buildInfoRow(Icons.phone_android, 'Phone', userPhone),
                      _buildInfoRow(Icons.star, 'Level', userLevel),
                      _buildInfoRow(
                        Icons.workspace_premium,
                        'Title',
                        userTitle,
                      ),
                      _buildInfoRow(
                        Icons.quiz,
                        'Total Quizzes',
                        '${userData['totalQuizzes'] ?? totalQuizzes}',
                      ),
                      _buildInfoRow(
                        Icons.emoji_events,
                        'Total Wins',
                        '${userData['totalWins'] ?? totalWins}',
                      ),
                      _buildInfoRow(
                        Icons.analytics,
                        'Accuracy',
                        '${(userData['accuracy'] ?? accuracy).toStringAsFixed(1)}%',
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Member Since',
                        _formatDate(userData['createdAt']),
                      ),
                      _buildInfoRow(
                        Icons.update,
                        'Last Updated',
                        _formatDate(userData['updatedAt']),
                      ),
                      _buildInfoRow(
                        Icons.security,
                        'Auth Method',
                        authMethod == 'email'
                            ? 'Email & Password'
                            : 'Phone Number',
                      ),
                      if (!isProfileCompleted && authMethod == 'phone')
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade300,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Profile incomplete. Add your name and email for better experience.',
                                  style: GoogleFonts.inter(
                                    color: Colors.orange.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        'Rank',
                        userData['rank'] ?? 'Beginner',
                        Icons.leaderboard,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatsCard(
                        'Points',
                        '${userData['points'] ?? 0}',
                        Icons.stars,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        'Quizzes Taken',
                        '${userData['totalQuizzes'] ?? totalQuizzes}',
                        Icons.quiz,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatsCard(
                        'Win Rate',
                        userData['totalQuizzes'] != null &&
                                userData['totalQuizzes']! > 0
                            ? '${((userData['totalWins'] ?? totalWins) / (userData['totalQuizzes'] ?? totalQuizzes) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.amber.shade200, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }
}
