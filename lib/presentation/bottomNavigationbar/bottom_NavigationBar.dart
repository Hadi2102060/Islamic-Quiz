import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiz_app/presentation/router/app_router.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}



class _BottomNavBarState extends State<BottomNavBar> {

int _selectedIndex = 0;

void _onBottomNavTap(int idx) {
  setState(() => _selectedIndex = idx);

  switch (idx) {
    case 0:
      // already on home
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
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B6B3A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (i) {
          final icons = [
            Icons.home,
            Icons.emoji_events,
            Icons.bar_chart,
            Icons.person,
          ];

          final labels = ['Home', 'Leaderboard', 'Stats', 'Profile'];

          final selected = _selectedIndex == i;

          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _onBottomNavTap(i);
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[i],
                    color: selected ? Colors.amber : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.amber : Colors.white70,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
