import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/screens/recommendations_screen.dart';
import 'package:flutter_appp/screens/reports_screen.dart';
import 'package:flutter_appp/screens/settings_screen.dart';
import 'package:flutter_appp/screens/tasks_screen.dart';
import 'mood_screen.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Задачи"),
          BottomNavigationBarItem(icon: Icon(Icons.mood), label: "Настроение"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Рекомендации"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Отчеты"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Настройки"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
