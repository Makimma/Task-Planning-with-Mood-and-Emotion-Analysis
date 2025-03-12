import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/mood_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = "Неделя";
  int tasksThisWeek = 0;
  int tasksThisMonth = 0;
  List<Map<String, dynamic>> moodData = [];

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
    int monthCount =
        await _getCompletedTasks(user.uid, DateTime(now.year, now.month, 1));

    setState(() {
      tasksThisWeek = weekCount;
      tasksThisMonth = monthCount;
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

    setState(() {
      moodData = snapshot.docs.map((doc) {
        return {
          "date": (doc['timestamp'] as Timestamp).toDate(),
          "mood": doc['type'],
          "note": doc['note'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Отчёты"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Задачи"),
              Tab(text: "Настроение"),
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
            _buildTaskReport(),
            _buildMoodReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskReport() {
    int displayedTasks =
        selectedPeriod == "Неделя" ? tasksThisWeek : tasksThisMonth;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Выполненные задачи:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ReportCard(
            title: selectedPeriod == "Неделя" ? "За неделю" : "За месяц",
            count: displayedTasks,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodReport() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: moodData.isEmpty
          ? Center(child: Text("Нет данных за этот период"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "График настроения:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Flexible(
                  fit: FlexFit.loose,
                  child: MoodChart(moodData: moodData),
                ),
              ],
            ),
    );
  }
}
