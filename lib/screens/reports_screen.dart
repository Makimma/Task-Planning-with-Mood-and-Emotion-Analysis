import 'package:fl_chart/fl_chart.dart';
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

  Map<String, int> moodProductivity = {};

  @override
  void initState() {
    super.initState();
    _fetchTaskCounts();
    _fetchMoodHistory();
    _fetchMoodProductivity();
  }

  void _fetchTaskCounts() async {
    User? user = TaskRepository.getCurrentUser();

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime startDate = selectedPeriod == "Неделя"
        ? today.subtract(Duration(days: 7))
        : today.subtract(Duration(days: 30));

    int weekCount = selectedPeriod == "Неделя"
        ? await _getCompletedTasks(user.uid, startDate)
        : 0;

    int monthCount = selectedPeriod == "Месяц"
        ? await _getCompletedTasks(user.uid, startDate)
        : 0;

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
    QuerySnapshot snapshot = await TaskRepository.getTasksByStatus("completed");

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
                  _fetchMoodProductivity();
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
              "Распределение выполненных задач:",
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
            SizedBox(height: 20),
            Text(
              "Распределение выполненных задач по настроению:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: 240,
              ),
              child: moodProductivity.isEmpty
                  ? Center(child: Text("Нет данных для анализа"))
                  : _buildMoodProductivityChart(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend("Радость", Colors.green),
                _buildLegend("Спокойствие", Colors.blue),
                _buildLegend("Усталость", Colors.orange),
                _buildLegend("Грусть", Colors.purple),
              ],
            ),
            SizedBox(height: 10),
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

  Widget _buildLegend(String mood, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        SizedBox(width: 4),
        Text(mood, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _fetchMoodProductivity() async {
    User? user = TaskRepository.getCurrentUser();

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    QuerySnapshot tasksSnapshot = await TaskRepository.getTasksByStatus("completed");
    QuerySnapshot moodsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .get();

    Map<DateTime, String> moodMap = {};
    for (var doc in moodsSnapshot.docs) {
      DateTime date = (doc['timestamp'] as Timestamp).toDate();
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      moodMap[normalizedDate] = doc['type'];
    }

    Map<String, int> counts = {};
    for (var taskDoc in tasksSnapshot.docs) {
      Timestamp completedAt = taskDoc['completedAt'] as Timestamp;
      DateTime taskDate = completedAt.toDate();
      if (taskDate.isBefore(startDate)) continue;

      DateTime normalizedTaskDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
      String? mood = moodMap[normalizedTaskDate];
      if (mood != null) {
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
    }

    setState(() {
      moodProductivity = counts;
    });
  }

  Widget _buildMoodProductivityChart() {
    final total = moodProductivity.values.fold(0, (a, b) => a + b);
    final sections = moodProductivity.entries.map((entry) {
      final double percent = total > 0 ? (entry.value / total * 100) : 0;
      return PieChartSectionData(
        value: percent,
        color: _getMoodColor(entry.key),
        title: '${percent.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          enabled: true,
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case "Радость":
        return Colors.green;
      case "Спокойствие":
        return Colors.blue;
      case "Усталость":
        return Colors.orange;
      case "Грусть":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

}
