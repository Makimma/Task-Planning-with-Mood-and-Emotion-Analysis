import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/services/task_repository.dart';

class ReportsDataProvider {
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

  bool _isInitialized = false;
  Map<String, Map<String, dynamic>> _periodCache = {};

  StreamSubscription? _moodProductivitySubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _moodsSubscription;

  bool get isInitialized => _isInitialized;

  bool hasCachedData(String period) => _periodCache.containsKey(period);

  Future<void> initialize(String period) async {
    selectedPeriod = period;
    await Future.wait([
      _fetchTaskCounts(),
      _fetchMoodHistory(),
      _fetchMoodProductivity(),
    ]);
    _isInitialized = true;
  }

  void dispose() {
    _moodProductivitySubscription?.cancel();
    _tasksSubscription?.cancel();
    _moodsSubscription?.cancel();
  }

  void restoreFromCache(String period) {
    final cachedData = _periodCache[period]!;
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
    productivityInsights = List<String>.from(cachedData['productivityInsights']);
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
      'productivityInsights': productivityInsights,
    };
  }

  Future<void> _fetchTaskCounts() async {
    // ... (перенести существующую логику из _fetchTaskCounts)
  }

  Future<void> _fetchMoodHistory() async {
    // ... (перенести существующую логику из _fetchMoodHistory)
  }

  Future<void> _fetchMoodProductivity() async {
    // ... (перенести существующую логику из _fetchMoodProductivity)
  }

  void _calculateMoodStatistics(List<Map<String, dynamic>> moods) {
    // ... (перенести существующую логику из _calculateMoodStatistics)
  }

  String getDayName(int weekday) {
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

  String getTaskWord(double count) {
    int intCount = count.round();
    if (intCount % 10 == 1 && intCount % 100 != 11) {
      return 'задача';
    } else if ([2, 3, 4].contains(intCount % 10) && ![12, 13, 14].contains(intCount % 100)) {
      return 'задачи';
    } else {
      return 'задач';
    }
  }

  String getComparisonText() {
    if (previousPeriodTasks == 0) return "Нет данных";
    if (taskChangePercentage == 0) return "Без изменений";
    String changeText = taskChangePercentage > 0 ? "больше" : "меньше";
    return "на ${taskChangePercentage.abs().toStringAsFixed(1)}% $changeText";
  }
} 