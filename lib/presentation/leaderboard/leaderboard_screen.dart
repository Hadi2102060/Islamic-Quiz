import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory ?? categories.first;
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      await _fetchCurrentUserData();
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Top row with back button and category selector
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
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCategoryDropdown()),
                  ],
                ),

                const SizedBox(height: 24), // Added spacing after category
                // Header banner
                Center(child: _buildHeader()),

                const SizedBox(height: 28), // Increased spacing after header
                /// PODIUM - Top 3 from selected category
                _buildPodiumSection(),

                const SizedBox(height: 28), // Increased spacing after podium
                /// LIST - Leaderboard for selected category
                Expanded(child: _buildLeaderboardList()),

                const SizedBox(height: 20), // Added spacing before invite
                /// INVITE and User Stats
                _buildInviteSection(context),
              ],
            ),
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
          style: const TextStyle(color: Colors.white, fontSize: 16),
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

  /// HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emoji_events_rounded, color: Colors.black),
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
    ).animate().fadeIn(duration: 500.ms).scale();
  }

  /// PODIUM - Top 3 from selected category
  Widget _buildPodiumSection() {
    if (selectedCategory == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('category', isEqualTo: selectedCategory)
          .orderBy('score', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final topUsers = snapshot.data?.docs ?? [];

        if (topUsers.isEmpty) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            child: const Text(
              'No scores yet in this category',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        // Prepare users list with proper indexing
        List<Map<String, dynamic>> podiumUsers = [];

        for (int i = 0; i < topUsers.length; i++) {
          final userData = topUsers[i].data() as Map<String, dynamic>;
          podiumUsers.add({
            'name': userData['userName'] ?? 'Anonymous',
            'score': userData['score'] ?? 0,
            'avatar': _getInitials(userData['userName'] ?? 'User'),
            'country': userData['country'] ?? '🌍',
            'badges': userData['badges'] ?? 0,
          });
        }

        // Ensure we have at least 3 items for podium layout
        while (podiumUsers.length < 3) {
          podiumUsers.add({
            'name': 'Empty Slot',
            'score': 0,
            'avatar': '--',
            'country': '🌍',
            'badges': 0,
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth * 0.28;

            return SizedBox(
              height: 200, // Increased height for better visibility
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  _buildPodiumTile(width, 2, podiumUsers[1]),

                  const SizedBox(width: 16), // Increased spacing
                  // 1st place
                  _buildPodiumTile(width, 1, podiumUsers[0], isWinner: true),

                  const SizedBox(width: 16), // Increased spacing
                  // 3rd place
                  _buildPodiumTile(width, 3, podiumUsers[2]),
                ],
              ),
            );
          },
        );
      },
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

  Widget _buildPodiumTile(
    double width,
    int rank,
    Map<String, dynamic> user, {
    bool isWinner = false,
  }) {
    final heights = [140.0, 160.0, 120.0];
    final height = heights[rank - 1];

    // Don't show if empty slot
    if (user['avatar'] == '--') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white38),
            ),
            const SizedBox(height: 6),
            const Text(
              'No player',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ).animate().slideY(begin: 0.4).fade();
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWinner
              ? [Colors.amber.shade300, Colors.amber.shade700]
              : [Colors.white24, Colors.white12],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: isWinner ? 28 : 22,
            backgroundColor: isWinner ? Colors.amber : Colors.white12,
            child: Text(
              user['avatar'],
              style: TextStyle(
                color: isWinner ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isWinner ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user['name'].split(" ").first,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Text(
            "#$rank",
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            "${user['score']} pts",
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ).animate().slideY(begin: 0.4).fade();
  }

  /// LIST - Full leaderboard for selected category
  Widget _buildLeaderboardList() {
    if (selectedCategory == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('category', isEqualTo: selectedCategory)
          .orderBy('score', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading leaderboard: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final results = snapshot.data?.docs ?? [];

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
                  'No scores yet in\n$selectedCategory',
                  textAlign: TextAlign.center,
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
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final userData = results[index].data() as Map<String, dynamic>;
            // In our Firestore structure, doc.id is NOT the user's uid
            // (it's usually "{uid}_{categoryId}"). Use the stored userId field.
            final userId = (userData['userId'] ?? results[index].id).toString();

            return _LeaderboardTile(
              index: index,
              userId: userId,
              userData: userData,
              isCurrentUser: userId == currentUserId,
            );
          },
        );
      },
    );
  }

  /// INVITE SECTION with User Stats
  Widget _buildInviteSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // User Stats Row
          if (currentUserId != null)
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('results')
                  .where('userId', isEqualTo: currentUserId)
                  .where('category', isEqualTo: selectedCategory)
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 30,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    ),
                  );
                }

                final hasResult = snapshot.data?.docs.isNotEmpty ?? false;
                final userResult = hasResult
                    ? snapshot.data!.docs.first.data() as Map<String, dynamic>
                    : null;
                final userScore = hasResult ? (userResult?['score'] ?? 0) : 0;

                return FutureBuilder<int?>(
                  future: hasResult ? _getUserRank(userScore as int) : null,
                  builder: (context, rankSnap) {
                    final rank = rankSnap.data;
                    final rankText = hasResult
                        ? (rank != null ? '#$rank' : '...')
                        : 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.black,
                            child: Text(
                              currentUserData?['name'] != null
                                  ? _getInitials(currentUserData!['name'])
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUserData?['name'] ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                if (hasResult)
                                  Text(
                                    'Rank: $rankText • $userScore pts',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  const Text(
                                    'No score yet in this category',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(
            height: 8,
          ), // Added spacing between user stats and invite
          // Invite Row
          Row(
            children: [
              const Icon(Icons.group_add, size: 28, color: Colors.black),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INVITE FRIENDS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Compete together and earn badges",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Share.share(
                    'Peace be upon you, I just played "The Quran Quiz" in the $selectedCategory category. '
                    'Check it out and join me: https://example.com/app_link',
                    subject: 'Join me in The Quran Quiz!',
                  );
                },
                child: const Text("Invite"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<int?> _getUserRank(int userScore) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('results')
          .where('category', isEqualTo: selectedCategory)
          .where('score', isGreaterThan: userScore)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      return null;
    }
  }
}

/// TILE
class _LeaderboardTile extends StatelessWidget {
  final int index;
  final String userId;
  final Map<String, dynamic> userData;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.index,
    required this.userId,
    required this.userData,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final medalColors = [Colors.amber, Colors.grey, Colors.brown];
    final isTopThree = index < 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.amber.withOpacity(0.2)
            : Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          /// RANK
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree
                  ? medalColors[index].withOpacity(.2)
                  : Colors.white12,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      Icons.emoji_events,
                      color: medalColors[index],
                      size: 20,
                    )
                  : Text(
                      "#${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),

          const SizedBox(width: 10),

          /// AVATAR
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            child: Text(
              _getInitials(userData['userName'] ?? 'User'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['userName'] ?? 'Anonymous',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.amber : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4, // Added runSpacing for better wrapping
                  children: [
                    _badge(
                      Icons.star,
                      "${userData['score'] ?? 0} pts",
                      Colors.amber,
                    ),
                    _badge(
                      Icons.badge,
                      "${userData['badges'] ?? 0} badges",
                      Colors.blue,
                    ),
                    if (userData['correctAnswers'] != null)
                      _badge(
                        Icons.check_circle,
                        "${userData['correctAnswers']}/${userData['totalQuestions']}",
                        Colors.green,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8), // Added spacing before trailing widget

          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Icon(Icons.trending_up, color: Colors.white38),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
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

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
