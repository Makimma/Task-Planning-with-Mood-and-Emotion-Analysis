import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/screens/main_screen.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isLogin = true;

  void _authenticate() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (!isLogin && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Пароли не совпадают")),
      );
      return;
    }

    User? user;
    if (isLogin) {
      user = await _authService.signInWithEmail(email, password);
    } else {
      user = await _authService.signUpWithEmail(email, password);
    }

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка ${isLogin ? 'входа' : 'регистрации'}")),
      );
    }
  }

  void _signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Вход в приложение")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            if (!isLogin)
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: "Подтвердите пароль"),
                obscureText: true,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text(isLogin ? "Войти" : "Зарегистрироваться"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin ? "Нет аккаунта? Зарегистрироваться" : "Уже есть аккаунт? Войти"),
            ),
            Divider(),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text("Войти через Google"),
            ),
          ],
        ),
      ),
    );
  }
}
