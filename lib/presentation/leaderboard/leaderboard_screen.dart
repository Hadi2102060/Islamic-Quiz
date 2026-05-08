import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:quiz_app/presentation/widgets/stats_background.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? initialCategory;

  const LeaderboardScreen({super.key, this.initialCategory});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? selectedCategory;
  final List<String> categories = [
    'Islamic Knowledge',
    'কুরআন ও হাদিস',
    'General Quiz',
    'Surahs Quiz',
    'Verses Quiz',
    'Prophets Quiz',
    'Seerah Quiz',
    'All Quiz - সব প্রশ্ন',
  ];

  String? currentUserId;
  Map<String, dynamic>? currentUserData;
  final Map<String, String> userPhotosCache = {};

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? categories.first;
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userId')?.trim();
    final phone = prefs.getString('userPhone')?.trim() ?? '';
    final derivedUserId = phone.replaceAll(RegExp(r'[^0-9]'), '');

    final userId = (savedUserId != null && savedUserId.isNotEmpty)
        ? savedUserId
        : (derivedUserId.isNotEmpty ? derivedUserId : null);

    if (userId == null) return;
    setState(() {
      currentUserId = userId;
    });
    await _fetchCurrentUserData();
  }

  Future<void> _fetchCurrentUserData() async {
    if (currentUserId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          currentUserData = userDoc.data();
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StatsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ===== FIXED TOP SECTION (Never scrolls) =====
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button & Category dropdown row
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
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryDropdown()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // "CHAMPIONS" Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "CHAMPIONS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 2,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(),

                    const SizedBox(height: 20),

                    // Top 3 Stat Cards (Horizontal)
                    _buildTopPlayersCards(),
                  ],
                ),
              ),

              // ===== SCROLLABLE LEADERBOARD LIST (Takes remaining space) =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLeaderboardList(currentUserId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF0B6B3A),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedCategory = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopPlayersCards() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('results')
            .orderBy('score', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final topUsers = docs
              .where(
                (doc) => _matchesSelectedCategory(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .take(3)
              .toList();

          // Prepare top 3 players with full data
          List<Map<String, dynamic>> topPlayers = [];
          for (int i = 0; i < topUsers.length; i++) {
            final userData = topUsers[i].data() as Map<String, dynamic>;
            topPlayers.add({
              'name': userData['userName'] ?? 'Anonymous',
              'score': userData['score'] ?? 0,
              'rank': i + 1,
              'initials': _getInitials(userData['userName'] ?? 'User'),
              'photo':
                  userData['profileImageBase64'] ??
                  userData['photoUrl'] ??
                  userData['photo'] ??
                  '',
              'userId': userData['userId'] ?? topUsers[i].id,
            });
          }

          // Fill empty slots
          while (topPlayers.length < 3) {
            topPlayers.add({
              'name': 'Empty',
              'score': 0,
              'rank': topPlayers.length + 1,
              'initials': '--',
              'photo': '',
              'userId': '',
            });
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd Place - Medium
              FutureBuilder<DocumentSnapshot?>(
                future: topPlayers[1]['userId'].toString().isNotEmpty
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(topPlayers[1]['userId'])
                          .get()
                    : Future.value(null),
                builder: (context, userSnapshot) {
                  Map<String, dynamic> playerWithPhoto = topPlayers[1];

                  if (userSnapshot.hasData &&
                      userSnapshot.data != null &&
                      userSnapshot.data!.exists) {
                    final userDoc =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    playerWithPhoto = {
                      ...topPlayers[1],
                      'photo':
                          userDoc['profileImageBase64'] ??
                          userDoc['photoUrl'] ??
                          userDoc['photo'] ??
                          '',
                    };
                  }

                  return Flexible(child: _buildPlayerCard(playerWithPhoto, 2));
                },
              ),
              const SizedBox(width: 8),
              // 1st Place - Largest
              FutureBuilder<DocumentSnapshot?>(
                future: topPlayers[0]['userId'].toString().isNotEmpty
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(topPlayers[0]['userId'])
                          .get()
                    : Future.value(null),
                builder: (context, userSnapshot) {
                  Map<String, dynamic> playerWithPhoto = topPlayers[0];

                  if (userSnapshot.hasData &&
                      userSnapshot.data != null &&
                      userSnapshot.data!.exists) {
                    final userDoc =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    playerWithPhoto = {
                      ...topPlayers[0],
                      'photo':
                          userDoc['profileImageBase64'] ??
                          userDoc['photoUrl'] ??
                          userDoc['photo'] ??
                          '',
                    };
                  }

                  return Flexible(child: _buildPlayerCard(playerWithPhoto, 1));
                },
              ),
              const SizedBox(width: 8),
              // 3rd Place - Smallest
              FutureBuilder<DocumentSnapshot?>(
                future: topPlayers[2]['userId'].toString().isNotEmpty
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(topPlayers[2]['userId'])
                          .get()
                    : Future.value(null),
                builder: (context, userSnapshot) {
                  Map<String, dynamic> playerWithPhoto = topPlayers[2];

                  if (userSnapshot.hasData &&
                      userSnapshot.data != null &&
                      userSnapshot.data!.exists) {
                    final userDoc =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    playerWithPhoto = {
                      ...topPlayers[2],
                      'photo':
                          userDoc['profileImageBase64'] ??
                          userDoc['photoUrl'] ??
                          userDoc['photo'] ??
                          '',
                    };
                  }

                  return Flexible(child: _buildPlayerCard(playerWithPhoto, 3));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int rank) {
    final colors = [
      [Colors.amber.shade300, Colors.amber.shade700],
      [Colors.cyan.shade200, Colors.cyan.shade600],
      [const Color(0xFFCD7F32), const Color(0xFFB87333)],
    ];

    final bgColors = [
      Colors.amber,
      Colors.cyan.shade400,
      const Color(0xFFCD7F32),
    ];

    // Hierarchical sizing: 1st > 2nd > 3rd
    final cardHeights = [140.0, 110.0, 85.0];
    final avatarRadii = [36.0, 28.0, 22.0];
    final nameFontSizes = [14.0, 12.0, 10.0];
    final scoreFontSizes = [13.0, 11.0, 9.0];

    final cardHeight = cardHeights[rank - 1];
    final avatarRadius = avatarRadii[rank - 1];
    final nameFontSize = nameFontSizes[rank - 1];
    final scoreFontSize = scoreFontSizes[rank - 1];

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors[rank - 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with photo
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: bgColors[rank - 1],
                backgroundImage: _getPlayerPhotoProvider(player),
                child: _getPlayerPhotoProvider(player) == null
                    ? Text(
                        player['initials'] ?? 'U',
                        style: TextStyle(
                          color: rank == 3 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: avatarRadius * 0.5,
                        ),
                      )
                    : null,
              ),
              // Rank badge
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade600,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '#${player['rank']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              player['name'].toString().split(" ").first,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: nameFontSize,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 3),
          // Score
          Text(
            "${player['score']} pts",
            style: TextStyle(color: Colors.white70, fontSize: scoreFontSize),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2).fade();
  }

  ImageProvider? _getPlayerPhotoProvider(Map<String, dynamic> player) {
    final photo =
        player['photo'] ??
        player['photoUrl'] ??
        player['profileImageBase64'] ??
        '';

    if (photo.isEmpty) return null;

    if (photo.startsWith('data:image')) {
      try {
        final base64String = photo.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }

    // Check if it's directly base64 (no data URI prefix)
    try {
      if (photo.length > 100 && !photo.startsWith('http')) {
        return MemoryImage(base64Decode(photo));
      }
    } catch (e) {
      // Not valid base64, continue
    }

    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }

    return null;
  }

  bool _matchesSelectedCategory(Map<String, dynamic> data) {
    if (selectedCategory != null && selectedCategory!.startsWith('All Quiz')) {
      return true;
    }

    final cat = (data['category'] ?? '')?.toString();
    final catTitle = (data['categoryTitle'] ?? '')?.toString();
    final catId = (data['categoryId'] ?? '')?.toString();

    return cat == selectedCategory ||
        catTitle == selectedCategory ||
        catId == selectedCategory;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  Future<String> _fetchUserPhoto(String userId) async {
    // Check cache first
    if (userPhotosCache.containsKey(userId)) {
      return userPhotosCache[userId] ?? '';
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Try all photo sources in priority order
        final photo =
            userData['profileImageBase64'] ??
            userData['photoUrl'] ??
            userData['photo'] ??
            '';
        userPhotosCache[userId] = photo;
        return photo;
      }
    } catch (e) {
      // Silently handle permission errors and other exceptions
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        print('Photo access denied for user: $userId');
      } else {
        print('Error fetching user photo: $e');
      }
    }

    // Cache empty result to avoid repeated failed attempts
    userPhotosCache[userId] = '';
    return '';
  }

  Widget _buildLeaderboardList(String? activeUserId) {
    if (selectedCategory == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .orderBy('score', descending: true)
          .limit(500)
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
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final resultsAll = snapshot.data?.docs ?? [];
        final results = resultsAll
            .where(
              (doc) =>
                  _matchesSelectedCategory(doc.data() as Map<String, dynamic>),
            )
            .toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No scores yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final userData = results[index].data() as Map<String, dynamic>;
            final userId = (userData['userId'] ?? results[index].id).toString();
            final isCurrentUser = userId == activeUserId;

            return FutureBuilder<String>(
              future: _fetchUserPhoto(userId),
              builder: (context, photoSnapshot) {
                final userDataWithPhoto = {
                  ...userData,
                  'photo': photoSnapshot.data ?? '',
                };

                return _LeaderboardTile(
                  index: index,
                  userData: userDataWithPhoto,
                  isCurrentUser: isCurrentUser,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> userData;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.index,
    required this.userData,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = index < 3;
    final name = userData['userName'] ?? 'Anonymous';
    final score = userData['score'] ?? 0;
    final badges = userData['badges'] ?? 0;
    final maxScore = userData['maxScore'] ?? 20;
    final initials = _getInitials(name);

    final medalColors = [Colors.amber, Colors.grey, Colors.brown];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.amber.withOpacity(0.2)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree
                  ? medalColors[index].withOpacity(0.2)
                  : Colors.white12,
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: isTopThree ? medalColors[index] : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar with Photo
          CircleAvatar(
            radius: 22,
            backgroundColor: isTopThree
                ? medalColors[index].withOpacity(0.3)
                : Colors.white12,
            backgroundImage: _getTilePhotoProvider(userData),
            child: _getTilePhotoProvider(userData) == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "$score pts",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$badges",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Score Progress
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.circle, color: Colors.red.shade400, size: 8),
                const SizedBox(height: 4),
                Text(
                  "$score/$maxScore",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  ImageProvider? _getTilePhotoProvider(Map<String, dynamic> userData) {
    // Try multiple photo sources
    final photo =
        userData['photo'] ??
        userData['photoUrl'] ??
        userData['profileImageBase64'] ??
        '';

    if (photo.isEmpty) return null;

    // Check if it's base64 data
    if (photo.startsWith('data:image')) {
      try {
        final base64String = photo.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }

    // Check if it's directly base64 (no data URI prefix)
    try {
      if (photo.length > 100 && !photo.startsWith('http')) {
        return MemoryImage(base64Decode(photo));
      }
    } catch (e) {
      // Not valid base64, continue
    }

    // Check if it's a URL
    if (photo.startsWith('http')) {
      return NetworkImage(photo);
    }

    return null;
  }
}
