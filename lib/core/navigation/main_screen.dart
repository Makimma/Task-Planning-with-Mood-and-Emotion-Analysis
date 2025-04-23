import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/features/recommendations/screens/recommendations_screen.dart';
import 'package:flutter_appp/features/reports/screens/reports_screen.dart';
import 'package:flutter_appp/features/settings/screens/settings_screen.dart';
import 'package:flutter_appp/features/tasks/screens/tasks_screen.dart';
import '../../features/moods/screens/mood_screen.dart';

class MainScreen extends StatefulWidget {
  final User user;

  MainScreen({required this.user});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    TasksScreen(),
    MoodScreen(),
    RecommendationsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          iconSize: 28,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.task),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mood),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }
}
