import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import 'package:intl/intl.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> tasks = [];
  String? currentMood;

  @override
  void initState() {
    super.initState();
    _fetchUserMood();
    _fetchTasks();
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

  void _fetchTasks() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('status', isEqualTo: 'active') // Только активные задачи
        .get();

    List<Map<String, dynamic>> fetchedTasks = snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        "title": doc["title"],
        "category": doc["category"],
        "deadline": (doc["deadline"] as Timestamp).toDate(),
        "priority": doc["priority"],
        "emotionalLoad": doc["emotionalLoad"],
      };
    }).toList();

    fetchedTasks.sort((a, b) => _calculatePriority(b).compareTo(_calculatePriority(a)));

    setState(() {
      tasks = fetchedTasks;
    });
  }

  double _calculatePriority(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    double deadlineFactor = 1 / ((task["deadline"].difference(now).inHours + 1).toDouble());

    double emotionalLoadFactor = _getEmotionalLoadFactor(task["emotionalLoad"]);

    Map<String, double> priorityMap = {"high": 1.0, "medium": 0.7, "low": 0.3};
    double priorityFactor = priorityMap[task["priority"]] ?? 0.3;

    return (deadlineFactor * 0.5) + (emotionalLoadFactor * 0.3) + (priorityFactor * 0.2);
  }

  double _getEmotionalLoadFactor(int load) {
    if (currentMood == "Радость") {
      return load / 5;
    } else if (currentMood == "Спокойствие") {
      return 1 - (pow((load - 3) / 4, 2)).toDouble(); // ✅ Исправлено
    } else if (currentMood == "Грусть") {
      return (5 - load) / 4;
    } else if (currentMood == "Усталость") {
      return (pow(((5 - load + 4) / 20), 2)).toDouble(); // ✅ Исправлено
    }
    return 0.5; // Значение по умолчанию
  }


  void _markTaskAsCompleted(String taskId) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({"status": "completed"}).then((_) {
      _fetchTasks();
    });
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
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text("Нет активных задач"))
                  : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  // return TaskCard(
                  //     task: task,
                  //     onEdit: () => _showEditTaskDialog(context, task),
                  //     onComplete: () => _completeTask(task['id']));
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(task["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Категория: ${task["category"]}"),
                          Text("Дедлайн: ${DateFormat('dd.MM.yyyy HH:mm').format(task["deadline"])}"),
                          Text("Эмоциональная нагрузка: ${task["emotionalLoad"]}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // TODO: Добавить переход на экран редактирования задачи
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              _markTaskAsCompleted(task["id"]);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
