import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/widgets/task_card.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  String? currentMood;

  @override
  void initState() {
    super.initState();
    _fetchUserMood();
  }

  void _fetchUserMood() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        currentMood = snapshot.docs.first['type'];
      });
    }
  }

  double _calculatePriority(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime deadline = (task["deadline"] as Timestamp).toDate();

    double deadlineFactor = 1 / ((deadline.difference(now).inHours + 1).toDouble());
    double emotionalLoadFactor = _getEmotionalLoadFactor(task["emotionalLoad"]);

    Map<String, double> priorityMap = {"high": 1.0, "medium": 0.7, "low": 0.3};
    double priorityFactor = priorityMap[task["priority"]] ?? 0.3;

    return (deadlineFactor * 0.5) + (emotionalLoadFactor * 0.3) + (priorityFactor * 0.2);
  }


  double _getEmotionalLoadFactor(int load) {
    if (currentMood == "Радость") {
      return load / 5;
    } else if (currentMood == "Спокойствие") {
      return 1 - (pow(load - 3, 2) / 4).toDouble();
    } else if (currentMood == "Грусть") {
      return (5 - load) / 4;
    } else if (currentMood == "Усталость") {
      return ((pow(5 - load, 2) + 4) / 20).toDouble();
    }
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Рекомендации")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentMood == null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Укажите ваше настроение, чтобы получать более точные рекомендации.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 10),
            Text(
              "Рекомендуемые задачи:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
    );
  }

  /// 🔥 **Используем `StreamBuilder`, чтобы автоматически обновлять задачи**
  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('tasks')
          .where('status', isEqualTo: 'active')
          .snapshots(), // ✅ Автоматическое обновление
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Нет активных задач"));
        }

        List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
          return {
            "id": doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        tasks.sort((a, b) => _calculatePriority(b).compareTo(_calculatePriority(a)));

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return TaskCard(
              task: task,
              onEdit: () => TaskActions.showEditTaskDialog(context, task),
              onComplete: () => TaskActions.completeTask(task['id']),
            );
          },
        );
      },
    );
  }
}
