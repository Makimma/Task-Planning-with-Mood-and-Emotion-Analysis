import 'package:flutter/material.dart';

class MoodScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настроение")),
      body: Center(child: Text("Выбор настроения")),
    );
  }
}
