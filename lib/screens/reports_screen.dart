import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/services/task_repository.dart';
import '../widgets/mood_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/report_card.dart';
import '../widgets/task_chart.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = "Неделя";
  int tasksThisWeek = 0;
  int tasksThisMonth = 0;
  List<Map<String, dynamic>> moodData = [];
  String dominantMood = "Нет данных";

  double positiveDaysPercentage = 0.0;
  double negativeDaysPercentage = 0.0;

  Map<String, int> categoryCounts = {};
  Map<String, int> priorityCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchTaskCounts();
    _fetchMoodHistory();
  }

  void _fetchTaskCounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    int weekCount = await _getCompletedTasks(user.uid, startDate);
    int monthCount = await _getCompletedTasks(user.uid, DateTime(now.year, now.month, 1));

    final categoryData = await _getCategoryStats(user.uid, startDate);
    final priorityData = await _getPriorityStats(user.uid, startDate);

    setState(() {
      tasksThisWeek = weekCount;
      tasksThisMonth = monthCount;

      categoryCounts = categoryData;
      priorityCounts = priorityData;
    });
  }

  Future<int> _getCompletedTasks(String userId, DateTime startDate) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .get();

    return snapshot.docs.where((doc) {
      Timestamp completedAt = doc['completedAt'] as Timestamp;
      return completedAt.toDate().isAfter(startDate);
    }).length;
  }

  void _fetchMoodHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: false)
        .get();

    List<Map<String, dynamic>> moods = snapshot.docs.map((doc) {
      return {
        "date": (doc['timestamp'] as Timestamp).toDate(),
        "mood": doc['type'],
      };
    }).toList();

    setState(() {
      moodData = snapshot.docs.map((doc) {
        return {
          "date": (doc['timestamp'] as Timestamp).toDate(),
          "mood": doc['type'],
          "note": doc['note'],
        };
      }).toList();
    });

    _calculateMoodStatistics(moods);
  }

  void _calculateMoodStatistics(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) {
      setState(() {
        dominantMood = "Нет данных";
        positiveDaysPercentage = 0.0;
        negativeDaysPercentage = 0.0;
      });
      return;
    }

    Map<String, int> moodCounts = {};
    int positiveDays = 0;
    int negativeDays = 0;

    for (var mood in moods) {
      String type = mood["mood"];
      moodCounts[type] = (moodCounts[type] ?? 0) + 1;

      if (type == "Радость" || type == "Спокойствие") {
        positiveDays++;
      } else {
        negativeDays++;
      }
    }

    String mostCommonMood =
        moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    int totalDays = moods.length;
    setState(() {
      dominantMood = mostCommonMood;
      positiveDaysPercentage = (positiveDays / totalDays) * 100;
      negativeDaysPercentage = (negativeDays / totalDays) * 100;
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Отчеты"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Обзор"),
              Tab(text: "Графики"),
            ],
          ),
          actions: [
            PeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: (value) {
                setState(() {
                  selectedPeriod = value;
                  _fetchTaskCounts();
                  _fetchMoodHistory();
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverviewReport(),
            _buildMoodReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewReport() {
    int displayedTasks =
        selectedPeriod == "Неделя" ? tasksThisWeek : tasksThisMonth;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Среднее настроение:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    "Преобладающее настроение: $dominantMood",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Позитивные дни: ${positiveDaysPercentage.toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Негативные дни: ${negativeDaysPercentage.toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Выполненные задачи:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ReportCard(
            title: selectedPeriod == "Неделя" ? "За неделю" : "За месяц",
            count: displayedTasks,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodReport() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "История настроения:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: 300,
              ),
              child: moodData.isEmpty
                  ? Center(child: Text("Нет данных за этот период"))
                  : MoodChart(moodData: moodData),
            ),

            SizedBox(height: 40),
            Text(
              "Распределение задач:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 300,
                maxHeight: 500,
              ),
              child: categoryCounts.isEmpty && priorityCounts.isEmpty
                  ? Center(child: Text("Нет данных о задачах"))
                  : TaskCharts(
                categoryCounts: categoryCounts,
                priorityCounts: priorityCounts,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getCategoryStats(String userId, DateTime startDate) async {
    final snapshot = await TaskRepository.getTasksByStatus("completed");

    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final completedAt = doc['completedAt'] as Timestamp?;
      if (completedAt != null && completedAt.toDate().isAfter(startDate)) {
        final category = doc['category'];
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<Map<String, int>> _getPriorityStats(String userId, DateTime startDate) async {
    final snapshot = await TaskRepository.getTasksByStatus("completed");

    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final completedAt = doc['completedAt'] as Timestamp?;
      if (completedAt != null && completedAt.toDate().isAfter(startDate)) {
        final priority = doc['priority'];
        counts[priority] = (counts[priority] ?? 0) + 1;
      }
    }
    return counts;
  }
}
