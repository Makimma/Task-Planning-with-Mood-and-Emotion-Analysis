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
import '../widgets/gradient_mood_icon.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = "Неделя";
  int tasksThisWeek = 0;
  int tasksThisMonth = 0;
  int previousPeriodTasks = 0;
  double taskChangePercentage = 0.0;
  List<Map<String, dynamic>> moodData = [];
  String dominantMood = "Нет данных";

  double positiveDaysPercentage = 0.0;
  double negativeDaysPercentage = 0.0;

  Map<String, int> categoryCounts = {};
  Map<String, int> priorityCounts = {};

  Map<String, int> moodProductivity = {};
  String mostProductiveMood = "Нет данных";
  double mostProductiveMoodRate = 0.0;
  List<String> productivityInsights = [];
  double moodChangePercentage = 0.0;
  String mostProductiveDay = "Нет данных";
  double averageTasksPerDay = 0.0;
  String mostProductiveDayForTasks = "Нет данных";
  int totalTasksCount = 0;
  double taskCompletionRate = 0.0;

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
      moodChangePercentage = cachedData['moodChangePercentage'];
      mostProductiveDay = cachedData['mostProductiveDay'];
      averageTasksPerDay = cachedData['averageTasksPerDay'];
      mostProductiveDayForTasks = cachedData['mostProductiveDayForTasks'];
      totalTasksCount = cachedData['totalTasksCount'];
      taskCompletionRate = cachedData['taskCompletionRate'];
      productivityInsights = List<String>.from(cachedData['productivityInsights']);
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
      'moodChangePercentage': moodChangePercentage,
      'mostProductiveDay': mostProductiveDay,
      'averageTasksPerDay': averageTasksPerDay,
      'mostProductiveDayForTasks': mostProductiveDayForTasks,
      'totalTasksCount': totalTasksCount,
      'taskCompletionRate': taskCompletionRate,
      'productivityInsights': productivityInsights,
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
    DateTime previousPeriodStart = selectedPeriod == "Неделя"
        ? startDate.subtract(Duration(days: 7))
        : startDate.subtract(Duration(days: 30));

    _tasksSubscription?.cancel();
    _tasksSubscription = TaskRepository.getTasksStream("completed").listen((snapshot) async {
      int weekCount = 0;
      int monthCount = 0;
      int previousCount = 0;
      Map<String, int> categoryData = {};
      Map<String, int> priorityData = {};
      Map<String, int> dayTaskCounts = {};

      for (var doc in snapshot.docs) {
        Timestamp? completedAt = doc['completedAt'] as Timestamp?;
        if (completedAt != null) {
          DateTime completionDate = completedAt.toDate();
          
          // Подсчет для текущего периода
          if (completionDate.isAfter(startDate)) {
            if (selectedPeriod == "Неделя") {
              weekCount++;
            } else {
              monthCount++;
            }

            String dayName = _getDayName(completionDate.weekday);
            dayTaskCounts[dayName] = (dayTaskCounts[dayName] ?? 0) + 1;

            String category = doc['category'];
            categoryData[category] = (categoryData[category] ?? 0) + 1;

            String priority = doc['priority'];
            priorityData[priority] = (priorityData[priority] ?? 0) + 1;
          }
          
          // Подсчет для предыдущего периода
          if (completionDate.isAfter(previousPeriodStart) && completionDate.isBefore(startDate)) {
            previousCount++;
          }
        }
      }

      // Рассчитываем процент изменения
      int currentPeriodTasks = selectedPeriod == "Неделя" ? weekCount : monthCount;
      double changePercentage = previousCount > 0 
          ? ((currentPeriodTasks - previousCount) / previousCount) * 100 
          : 0.0;

      if (mounted) {
        setState(() {
          tasksThisWeek = weekCount;
          tasksThisMonth = monthCount;
          previousPeriodTasks = previousCount;
          taskChangePercentage = changePercentage;
          categoryCounts = categoryData;
          priorityCounts = priorityData;
          averageTasksPerDay = (selectedPeriod == "Неделя" ? weekCount : monthCount) / 
              (selectedPeriod == "Неделя" ? 7 : 30);

          if (dayTaskCounts.isNotEmpty) {
            mostProductiveDayForTasks = dayTaskCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
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
          _calculateMoodStatistics(moods);
        });
        _saveToCache();
      }
    }, onError: (error) {
      print('Error fetching mood history: $error');
    });
  }

  void _calculateMoodStatistics(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) {
      setState(() {
        dominantMood = "Нет данных";
        positiveDaysPercentage = 0.0;
        negativeDaysPercentage = 0.0;
        moodChangePercentage = 0.0;
        mostProductiveDay = "Нет данных";
      });
      return;
    }

    Map<String, int> moodCounts = {};
    Map<String, int> dayOfWeekCounts = {};
    int positiveDays = 0;
    int negativeDays = 0;

    // Группируем настроения по дням недели
    for (var mood in moods) {
      String type = mood["mood"];
      DateTime date = mood["date"];
      String dayName = _getDayName(date.weekday);
      
      moodCounts[type] = (moodCounts[type] ?? 0) + 1;
      
      if (type == "Радость" || type == "Спокойствие") {
        positiveDays++;
        dayOfWeekCounts[dayName] = (dayOfWeekCounts[dayName] ?? 0) + 1;
      } else if (type == "Грусть" || type == "Усталость") {
        negativeDays++;
      }
    }

    // Находим день с наибольшим количеством позитивных настроений
    if (dayOfWeekCounts.isNotEmpty) {
      mostProductiveDay = dayOfWeekCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    String mostCommonMood = moodCounts.entries.isEmpty 
        ? "Нет данных" 
        : moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    int totalDays = moods.length;
    
    // Рассчитываем изменение настроения по сравнению с предыдущим периодом
    double previousPositivePercentage = positiveDaysPercentage;
    double currentPositivePercentage = totalDays > 0 ? (positiveDays / totalDays) * 100 : 0.0;
    
    if (previousPositivePercentage > 0) {
      moodChangePercentage = ((currentPositivePercentage - previousPositivePercentage) / previousPositivePercentage) * 100;
    }

    if (mounted) {
      setState(() {
        dominantMood = mostCommonMood;
        positiveDaysPercentage = currentPositivePercentage;
        negativeDaysPercentage = totalDays > 0 ? (negativeDays / totalDays) * 100 : 0.0;
      });
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Понедельник";
      case 2: return "Вторник";
      case 3: return "Среда";
      case 4: return "Четверг";
      case 5: return "Пятница";
      case 6: return "Суббота";
      case 7: return "Воскресенье";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Отчеты",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          titleSpacing: 16,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: PeriodSelector(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                      _isInitialized = false;
                    });
                    _initializeData();
                  },
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, size: 18),
                    SizedBox(width: 8),
                    Text('Обзор'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Графики'),
                  ],
                ),
              ),
            ],
          ),
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
    int displayedTasks = selectedPeriod == "Неделя" ? tasksThisWeek : tasksThisMonth;

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Функция для склонения слова "задача" для дробных чисел
    String _getTaskWordForDecimal(double number) {
      if (number >= 5 || number == 0) return "задач";
      if (number >= 2 && number < 5) return "задачи";
      if (number >= 1 && number < 2) return "задача";
      double fraction = number - number.floor();
      if (fraction > 0) return "задачи";
      return "задач";
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Среднее настроение",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      GradientMoodIcon(
                        mood: dominantMood,
                        size: 40,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Преобладающее настроение: $dominantMood",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (moodChangePercentage != 0) ...[
                              SizedBox(height: 4),
                              Text(
                                moodChangePercentage > 0
                                    ? "На ${moodChangePercentage.abs().toStringAsFixed(1)}% лучше, чем в прошлый ${selectedPeriod.toLowerCase()}"
                                    : "На ${moodChangePercentage.abs().toStringAsFixed(1)}% хуже, чем в прошлый ${selectedPeriod.toLowerCase()}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: moodChangePercentage > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                            if (mostProductiveDay != "Нет данных") ...[
                              SizedBox(height: 4),
                              Text(
                                "Лучший день недели: $mostProductiveDay",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMoodStatCard(
                          "Позитивные дни",
                          "${positiveDaysPercentage.toStringAsFixed(1)}%",
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMoodStatCard(
                          "Негативные дни",
                          "${negativeDaysPercentage.toStringAsFixed(1)}%",
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Выполненные задачи",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  ReportCard(
                    title: selectedPeriod == "Неделя" ? "За неделю" : "За месяц",
                    count: displayedTasks,
                    suffix: _getTaskWord(displayedTasks.toDouble()),
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskStatRow(
                        "В среднем в день:",
                        "${averageTasksPerDay.toStringAsFixed(1)} ${_getTaskWordForDecimal(averageTasksPerDay)}",
                      ),
                      if (mostProductiveDayForTasks != "Нет данных")
                        _buildTaskStatRow(
                          "Самый продуктивный день:",
                          mostProductiveDayForTasks,
                        ),
                      _buildTaskStatRow(
                        "Сравнение:",
                        _getComparisonText(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "История настроения",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: 300,
                    ),
                    child: moodData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "Нет данных за этот период",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : MoodChart(moodData: moodData),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Распределение задач",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 500,
                      maxHeight: 700,
                    ),
                    child: categoryCounts.isEmpty && priorityCounts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_alt, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "Нет данных о задачах",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TaskCharts(
                            categoryCounts: categoryCounts,
                            priorityCounts: priorityCounts,
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Продуктивность по настроению",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 700,
                    child: moodProductivity.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  "Нет данных для анализа",
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              if (productivityInsights.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Анализ продуктивности",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ...productivityInsights.map((insight) => Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Icon(
                                                Icons.lightbulb_outline,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                insight,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )).toList(),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                              ],
                              Expanded(
                                flex: 2,
                                child: AspectRatio(
                                  aspectRatio: 1.5,
                                  child: PieChart(
                                    PieChartData(
                                      sections: moodProductivity.entries.map((entry) {
                                        final total = moodProductivity.values.fold(0, (a, b) => a + b);
                                        final double percent = total > 0 ? (entry.value / total * 100) : 0;
                                        final color = _getMoodColor(entry.key);
                                        return PieChartSectionData(
                                          value: percent,
                                          color: color,
                                          title: '${percent.toStringAsFixed(1)}%',
                                          radius: 50,
                                          titleStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 3,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                        enabled: true,
                                      ),
                                      borderData: FlBorderData(show: false),
                                    ),
                                    swapAnimationDuration: Duration(milliseconds: 800),
                                    swapAnimationCurve: Curves.easeInOutQuart,
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildMoodProductivityLegend("Радость", Colors.green),
                                    _buildMoodProductivityLegend("Спокойствие", Colors.blue),
                                    _buildMoodProductivityLegend("Усталость", Colors.orange),
                                    _buildMoodProductivityLegend("Грусть", Colors.purple),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodProductivityLegend(String mood, Color color) {
    final count = moodProductivity[mood] ?? 0;
    final total = moodProductivity.values.fold(0, (a, b) => a + b);
    final percent = total > 0 ? (count / total * 100) : 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                mood,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            SizedBox(height: 4),
            Text(
              '$count ${_getTaskWord(count.toDouble())} (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
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

    _moodProductivitySubscription?.cancel();

    Stream<QuerySnapshot> tasksStream = TaskRepository.getTasksStream("completed");
    Stream<QuerySnapshot> moodsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .snapshots();

    _moodProductivitySubscription = tasksStream.listen((tasksSnapshot) {
      moodsStream.listen((moodsSnapshot) {
        Map<DateTime, String> moodMap = {};
        Map<String, int> moodDays = {};
        
        for (var doc in moodsSnapshot.docs) {
          DateTime date = (doc['timestamp'] as Timestamp).toDate();
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);
          String mood = doc['type'];
          moodMap[normalizedDate] = mood;
          moodDays[mood] = (moodDays[mood] ?? 0) + 1;
        }

        Map<String, int> counts = {};
        Map<String, double> productivityRates = {};
        
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

        // Рассчитываем среднюю продуктивность для каждого настроения
        moodDays.forEach((mood, days) {
          if (days > 0) {
            productivityRates[mood] = (counts[mood] ?? 0) / days;
          }
        });

        // Находим самое продуктивное настроение
        if (productivityRates.isNotEmpty) {
          var maxEntry = productivityRates.entries.reduce((a, b) => a.value > b.value ? a : b);
          mostProductiveMood = maxEntry.key;
          mostProductiveMoodRate = maxEntry.value;
        }

        // Генерируем инсайты
        List<String> insights = [];
        
        if (mostProductiveMood != "Нет данных") {
          insights.add("Вы наиболее продуктивны когда испытываете $mostProductiveMood (${mostProductiveMoodRate.toStringAsFixed(1)} задач в день)");
        }

        if (productivityRates.length >= 2) {
          var sortedRates = productivityRates.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          if (sortedRates.length >= 2) {
            var difference = sortedRates[0].value - sortedRates.last.value;
            if (difference > 1) {
              insights.add("Разница в продуктивности между лучшим и худшим настроением: ${difference.toStringAsFixed(1)} задач в день");
            }
          }
        }

        // Добавляем рекомендации
        if (mostProductiveMood == "Радость" || mostProductiveMood == "Спокойствие") {
          insights.add("Рекомендуется планировать важные задачи на периоды хорошего настроения");
        } else if (counts.containsKey("Усталость") && (counts["Усталость"] ?? 0) > 0) {
          insights.add("При усталости лучше делать небольшие, простые задачи");
        }

        setState(() {
          moodProductivity = counts;
          productivityInsights = insights;
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

  String _getTaskWord(double count) {
    int intCount = count.round();
    if (intCount % 10 == 1 && intCount % 100 != 11) {
      return 'задача';
    } else if ([2, 3, 4].contains(intCount % 10) && ![12, 13, 14].contains(intCount % 100)) {
      return 'задачи';
    } else {
      return 'задач';
    }
  }

  String _getComparisonText() {
    if (previousPeriodTasks == 0) return "Нет данных";
    
    if (taskChangePercentage == 0) {
      return "Без изменений";
    }
    
    String changeText = taskChangePercentage > 0 ? "больше" : "меньше";
    return "на ${taskChangePercentage.abs().toStringAsFixed(1)}% $changeText";
  }

}
