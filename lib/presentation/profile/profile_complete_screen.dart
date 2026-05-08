import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz_app/presentation/profile/profile_screen2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompleteScreen extends StatefulWidget {
  const ProfileCompleteScreen({super.key});

  @override
  State<ProfileCompleteScreen> createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  String? _profileImageBase64;

  String _userIdFromPrefs = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('userPhone');
    final savedUserId = prefs.getString('userId');
    setState(() {
      _userIdFromPrefs = (savedUserId ?? savedPhone ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    });

    final cu = _auth.currentUser;
    if (cu != null && _userIdFromPrefs.isEmpty) {
      _userIdFromPrefs = cu.uid;
    }

    if (_userIdFromPrefs.isNotEmpty) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_userIdFromPrefs)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _nameCtrl.text = (data['name'] ?? '').toString();
          _emailCtrl.text = (data['email'] ?? '').toString();
          _profileImageBase64 = (data['profileImageBase64'] ?? '').toString();
          _phoneCtrl.text = (data['phoneNumber'] ?? '').toString();
        }
      } catch (_) {}
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (xfile == null) return;
      final f = File(xfile.path);
      final bytes = await f.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _profileImageBase64 = b64;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userIdFromPrefs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user id found')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userPayload = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        userPayload['profileImageBase64'] = _profileImageBase64 as Object;
      }

      await _firestore
          .collection('users')
          .doc(_userIdFromPrefs)
          .set(userPayload, SetOptions(merge: true));

      final leaderboardPayload = {
        'userName': _nameCtrl.text.trim(),
        'lastPlayed': FieldValue.serverTimestamp(),
      };
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        leaderboardPayload['profileImageBase64'] =
            _profileImageBase64 as Object;
      }

      final phoneToSave = _phoneCtrl.text.trim();
      if (phoneToSave.isNotEmpty) {
        userPayload['phoneNumber'] = phoneToSave;
        leaderboardPayload['phoneNumber'] = phoneToSave;
      }

      await _firestore
          .collection('leaderboard')
          .doc(_userIdFromPrefs)
          .set(leaderboardPayload, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      // persist phone locally for other screens
      try {
        final prefs = await SharedPreferences.getInstance();
        if (phoneToSave.isNotEmpty)
          await prefs.setString('userPhone', phoneToSave);
        await prefs.setString('userId', _userIdFromPrefs);
      } catch (_) {}

      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Profile', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF073E3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePageScreen2()),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white12,
                        backgroundImage:
                            _profileImageBase64 != null &&
                                _profileImageBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(_profileImageBase64!))
                                  as ImageProvider
                            : null,
                        child:
                            _profileImageBase64 == null ||
                                _profileImageBase64!.isEmpty
                            ? Icon(
                                Icons.account_circle,
                                color: Colors.white54,
                                size: 64,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text('Choose Image', style: GoogleFonts.inter()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final re = RegExp(r"^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
                  return re.hasMatch(v.trim()) ? null : 'Enter valid email';
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
