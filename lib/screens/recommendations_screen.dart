import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Рекомендации")),
      body: Center(child: Text("Персонализированные рекомендации")),
    );
  }
}
