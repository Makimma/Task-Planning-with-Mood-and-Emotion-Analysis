import 'dart:async';

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

class _ReportsScreenState extends State<ReportsScreen> with AutomaticKeepAliveClientMixin {
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

  bool isLoading = false;
  bool _isInitialized = false;

  // Кэш для хранения данных по периодам
  Map<String, Map<String, dynamic>> _periodCache = {};

  StreamSubscription? _moodProductivitySubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _moodsSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized && _periodCache.containsKey(selectedPeriod)) {
      _restoreFromCache();
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      _moodProductivitySubscription?.cancel();
      _tasksSubscription?.cancel();
      _moodsSubscription?.cancel();

      await _fetchTaskCounts();
      await _fetchMoodHistory();
      await _fetchMoodProductivity();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isInitialized = true;
        });
      }
    }
  }

  void _restoreFromCache() {
    final cachedData = _periodCache[selectedPeriod]!;
    setState(() {
      tasksThisWeek = cachedData['tasksThisWeek'];
      tasksThisMonth = cachedData['tasksThisMonth'];
      moodData = List<Map<String, dynamic>>.from(cachedData['moodData']);
      dominantMood = cachedData['dominantMood'];
      positiveDaysPercentage = cachedData['positiveDaysPercentage'];
      negativeDaysPercentage = cachedData['negativeDaysPercentage'];
      categoryCounts = Map<String, int>.from(cachedData['categoryCounts']);
      priorityCounts = Map<String, int>.from(cachedData['priorityCounts']);
      moodProductivity = Map<String, int>.from(cachedData['moodProductivity']);
    });
  }

  void _saveToCache() {
    _periodCache[selectedPeriod] = {
      'tasksThisWeek': tasksThisWeek,
      'tasksThisMonth': tasksThisMonth,
      'moodData': moodData,
      'dominantMood': dominantMood,
      'positiveDaysPercentage': positiveDaysPercentage,
      'negativeDaysPercentage': negativeDaysPercentage,
      'categoryCounts': categoryCounts,
      'priorityCounts': priorityCounts,
      'moodProductivity': moodProductivity,
    };
  }

  @override
  void dispose() {
    _moodProductivitySubscription?.cancel();
    _tasksSubscription?.cancel();
    _moodsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchTaskCounts() async {
    User? user = TaskRepository.getCurrentUser();
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime startDate = selectedPeriod == "Неделя"
        ? today.subtract(Duration(days: 7))
        : today.subtract(Duration(days: 30));

    _tasksSubscription?.cancel();
    _tasksSubscription = TaskRepository.getTasksStream("completed").listen((snapshot) {
      int weekCount = 0;
      int monthCount = 0;
      Map<String, int> categoryData = {};
      Map<String, int> priorityData = {};

      for (var doc in snapshot.docs) {
        Timestamp? completedAt = doc['completedAt'] as Timestamp?;
        if (completedAt != null && completedAt.toDate().isAfter(startDate)) {
          if (selectedPeriod == "Неделя") {
            weekCount++;
          } else {
            monthCount++;
          }

          String category = doc['category'];
          categoryData[category] = (categoryData[category] ?? 0) + 1;

          String priority = doc['priority'];
          priorityData[priority] = (priorityData[priority] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          tasksThisWeek = weekCount;
          tasksThisMonth = monthCount;
          categoryCounts = categoryData;
          priorityCounts = priorityData;
        });
        _saveToCache();
      }
    }, onError: (error) {
      print('Error fetching task counts: $error');
    });
  }

  Future<void> _fetchMoodHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    _moodsSubscription?.cancel();
    _moodsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> moods = [];
      List<Map<String, dynamic>> moodData = [];

      for (var doc in snapshot.docs) {
        DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
        if (timestamp.isAfter(startDate)) {
          moods.add({
            "date": timestamp,
            "mood": doc['type'],
          });
          
          moodData.add({
            "date": timestamp,
            "mood": doc['type'],
            "note": doc['note'],
          });
        }
      }

      if (mounted) {
        setState(() {
          this.moodData = moodData;
        });
        _calculateMoodStatistics(moods);
        _saveToCache();
      }
    });
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
                  _isInitialized = false; // Сбрасываем флаг инициализации
                });
                _initializeData(); // Загружаем новые данные
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

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

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
            color: Theme.of(context).cardColor,
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

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
                  ? Center(child: Text("Нет данных за этот период", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),))
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
                  ? Center(child: Text("Нет данных о задачах", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
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
    setState(() {
      isLoading = true;
    });

    User? user = TaskRepository.getCurrentUser();
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    // Отменяем предыдущую подписку, если она существует
    _moodProductivitySubscription?.cancel();

    // Создаем Stream для задач
    Stream<QuerySnapshot> tasksStream = TaskRepository.getTasksStream("completed");
    // Создаем Stream для настроений
    Stream<QuerySnapshot> moodsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .snapshots();

    // Объединяем два Stream'а
    _moodProductivitySubscription = tasksStream.listen((tasksSnapshot) {
      moodsStream.listen((moodsSnapshot) {
        Map<DateTime, String> moodMap = {};
        for (var doc in moodsSnapshot.docs) {
          DateTime date = (doc['timestamp'] as Timestamp).toDate();
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);
          moodMap[normalizedDate] = doc['type'];
        }

        Map<String, int> counts = {};
        for (var taskDoc in tasksSnapshot.docs) {
          Timestamp? completedAt = taskDoc['completedAt'] as Timestamp?;
          if (completedAt != null) {
            DateTime taskDate = completedAt.toDate();
            if (taskDate.isAfter(startDate)) {
              DateTime normalizedTaskDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
              String? mood = moodMap[normalizedTaskDate];
              if (mood != null) {
                counts[mood] = (counts[mood] ?? 0) + 1;
              }
            }
          }
        }

        setState(() {
          moodProductivity = counts;
          isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          isLoading = false;
        });
        print('Error fetching mood productivity: $error');
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching tasks: $error');
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
