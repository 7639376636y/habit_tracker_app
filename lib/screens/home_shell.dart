import 'package:flutter/material.dart';
import 'habit_tracker_screen.dart';
import 'habits_page.dart';
import 'reports_page.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;

    // Mobile screens (separate focused screens)
    final mobileScreens = [
      const HabitsPage(),
      const ReportsPage(),
      const ProfileScreen(),
    ];

    // For desktop/web, just show the full HabitTrackerScreen with 3-dot menu
    if (isDesktop) {
      return const HabitTrackerScreen();
    }

    // For mobile/tablet, show bottom navigation with 3 tabs (Habits, Reports, Profile)
    return Scaffold(
      body: mobileScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey[400],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_rounded),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
