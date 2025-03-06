import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  final AuthService _authService = AuthService();

  HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Добро пожаловать, ${user.displayName}!"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoURL ?? ""),
              radius: 40,
            ),
            SizedBox(height: 20),
            Text("Имя: ${user.displayName}", style: TextStyle(fontSize: 18)),
            Text("Email: ${user.email}", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
