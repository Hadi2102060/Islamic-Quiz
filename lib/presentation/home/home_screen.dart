import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/data/providers/quiz_provider.dart';
import 'package:quiz_app/presentation/home/components/app_bottom_nav_bar.dart';
import 'package:quiz_app/presentation/home/components/home_drawer.dart';
import 'package:quiz_app/presentation/router/app_router.dart';
import 'package:quiz_app/presentation/widgets/stats_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  Future<bool> _isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone')?.trim() ?? '';
      return userPhone.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'প্রবেশাধিকার প্রয়োজন',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'এই বৈশিষ্ট্যটি ব্যবহার করতে আপনাকে প্রথমে লগইন করতে হবে। এখনই লগইন করুন এবং কুইজ খেলা শুরু করুন।',
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0B6B3A),
            ),
            child: const Text(
              'বাতিল',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              AppRouter.router.go(AppRouter.login);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B6B3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'লগইন করুন',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0: // already here
        break;
      case 1:
        AppRouter.router.push(AppRouter.leaderboard);
        break;
      case 2:
        AppRouter.router.push(AppRouter.stats);
        break;
      case 3:
        AppRouter.router.push(AppRouter.profile);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0B6B3A),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(quizCategoriesProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: 40,
      drawer: const HomeDrawer(),
      backgroundColor: Colors.transparent,
      body: StatsBackground(
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      final q = _query.trim().toLowerCase();
                      final filtered = q.isEmpty
                          ? categories
                          : categories.where((c) {
                              final title = (c.title?.toString() ?? '')
                                  .toLowerCase();
                              return title.contains(q);
                            }).toList();
                      return _buildCategoryList(filtered);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 28),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48), // for balance
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_query.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              splashRadius: 18,
              tooltip: 'Clear',
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final cardColors = [
      const Color(0xFFD93952),
      const Color(0xFFF08B1A),
      const Color(0xFFF3D03E),
      const Color(0xFF1E90FF),
      const Color(0xFF1A1633),
      const Color(0xFF6A1B9A),
      const Color(0xFF43A047),
      const Color(0xFF00ACC1),
    ];

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = categories[index];
        final bg = cardColors[index % cardColors.length];

        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            final isLoggedIn = await _isUserLoggedIn();
            if (!isLoggedIn) {
              _showLoginDialog();
              return;
            }
            if (mounted) {
              AppRouter.router.go('${AppRouter.quiz}/${item.id}', extra: item);
            }
          },
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
