import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appp/features/tasks/services/task_repository.dart';
import 'package:flutter_appp/features/reports/models/report_model.dart';

class ReportService {
  static final Map<String, Map<String, dynamic>> _periodCache = {};
  StreamSubscription? _moodProductivitySubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _moodsSubscription;
  final StreamController<void> _dataChangedController = StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangedController.stream;

  String _selectedPeriod = "Неделя";
  ReportModel? _cachedReport;

  ReportService() {
    _initStreams();
  }

  void setPeriod(String period, {bool force = false}) {
    if (_selectedPeriod != period || force) {
      _selectedPeriod = period;
      _initStreams();
    }
  }

  ReportModel? getCachedReport() => _cachedReport;

  void _initStreams() {
    _tasksSubscription?.cancel();
    _moodsSubscription?.cancel();
    _moodProductivitySubscription?.cancel();
    _fetchAndListen();
  }

  void _fetchAndListen() async {
    User? user = TaskRepository.getCurrentUser();
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime startDate = _selectedPeriod == "Неделя"
        ? today.subtract(Duration(days: 7))
        : today.subtract(Duration(days: 30));
    DateTime previousPeriodStart = _selectedPeriod == "Неделя"
        ? startDate.subtract(Duration(days: 7))
        : startDate.subtract(Duration(days: 30));


    _tasksSubscription = TaskRepository.getTasksStream("completed").listen((tasksSnapshot) async {
      _moodsSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((moodsSnapshot) async {
        int weekCount = 0;
        int monthCount = 0;
        int previousCount = 0;
        Map<String, int> categoryData = {};
        Map<String, int> priorityData = {};
        Map<String, int> dayTaskCounts = {};
        List<Map<String, dynamic>> moodsList = [];
        Map<DateTime, String> moodMap = {};
        Map<String, int> moodDays = {};
        for (var doc in moodsSnapshot.docs) {
          DateTime date = (doc['timestamp'] as Timestamp).toDate();
          if (date.isAfter(startDate)) {
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            String mood = doc['type'];
            moodMap[normalizedDate] = mood;
            moodDays[mood] = (moodDays[mood] ?? 0) + 1;
            moodsList.add({
              "date": date,
              "mood": mood,
              "note": doc['note'],
            });
          }
        }
        final prefs = await SharedPreferences.getInstance();
        final localMoodString = prefs.getString('current_mood');

        Map<String, dynamic>? localMoodData;
        DateTime? localMoodDate;

        if (localMoodString != null) {
          localMoodData = json.decode(localMoodString);
          localMoodDate = DateTime.parse(localMoodData?['timestamp']);
        }

        if (localMoodData != null && localMoodDate != null && localMoodDate.isAfter(startDate)) {
          final dateKey = DateTime(localMoodDate.year, localMoodDate.month, localMoodDate.day);
          moodsList.removeWhere((m) {
            final d = m['date'] as DateTime;
            return d.year == localMoodDate?.year && d.month == localMoodDate?.month && d.day == localMoodDate?.day;
          });
          moodMap[dateKey] = localMoodData['type'];
          moodDays[localMoodData['type']] = (moodDays[localMoodData['type']] ?? 0) + 1;
          moodsList.add({
            "date": localMoodDate,
            "mood": localMoodData['type'],
            "note": localMoodData['note'],
          });
        }

        for (var doc in tasksSnapshot.docs) {
          Timestamp? completedAt = doc['completedAt'] as Timestamp?;
          if (completedAt != null) {
            DateTime completionDate = completedAt.toDate();
            if (completionDate.isAfter(startDate)) {
              if (_selectedPeriod == "Неделя") {
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
            if (completionDate.isAfter(previousPeriodStart) && completionDate.isBefore(startDate)) {
              previousCount++;
            }
          }
        }
        int currentPeriodTasks = _selectedPeriod == "Неделя" ? weekCount : monthCount;
        double changePercentage = previousCount > 0 
            ? ((currentPeriodTasks - previousCount) / previousCount) * 100 
            : 0.0;
        String mostProductiveDayForTasks = dayTaskCounts.isNotEmpty
            ? dayTaskCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : "Нет данных";
        double averageTasksPerDay = (_selectedPeriod == "Неделя" ? weekCount : monthCount) / 
            (_selectedPeriod == "Неделя" ? 7 : 30);

        Map<String, int> moodProductivity = {};
        Map<String, double> productivityRates = {};
        for (var taskDoc in tasksSnapshot.docs) {
          Timestamp? completedAt = taskDoc['completedAt'] as Timestamp?;
          if (completedAt != null) {
            DateTime taskDate = completedAt.toDate();
            if (taskDate.isAfter(startDate)) {
              DateTime normalizedTaskDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
              String? mood = moodMap[normalizedTaskDate];
              if (mood != null) {
                moodProductivity[mood] = (moodProductivity[mood] ?? 0) + 1;
              }
            }
          }
        }
        moodDays.forEach((mood, days) {
          if (days > 0) {
            productivityRates[mood] = (moodProductivity[mood] ?? 0) / days;
          }
        });
        String mostProductiveMood = "Нет данных";
        double mostProductiveMoodRate = 0.0;
        if (productivityRates.isNotEmpty) {
          var maxEntry = productivityRates.entries.reduce((a, b) => a.value > b.value ? a : b);
          mostProductiveMood = maxEntry.key;
          mostProductiveMoodRate = maxEntry.value;
        }
        List<String> insights = [];
        if (mostProductiveMood != "Нет данных") {
          insights.add("Вы наиболее продуктивны когда испытываете $mostProductiveMood (${mostProductiveMoodRate.toStringAsFixed(1)} задач в день)");
        }
        if (productivityRates.length >= 2) {
          var sortedRates = productivityRates.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          if (sortedRates.length >= 2) {
            var difference = sortedRates[0].value - sortedRates.last.value;
            if (difference > 0.1) {
              insights.add("Разница в продуктивности между лучшим и худшим настроением: ${difference.toStringAsFixed(1)} задач в день");
            }
          }
        }

        if (moodDays.containsKey("Усталость") && (moodDays["Усталость"] ?? 0) > 0) {
          insights.add("При усталости лучше делать небольшие, простые задачи");
        } else if (moodDays.containsKey("Грусть") && (moodDays["Грусть"] ?? 0) > 0) {
          insights.add("В периоды грусти важно чередовать сложные и простые задачи");
        } else if (mostProductiveMood == "Радость" || mostProductiveMood == "Спокойствие") {
          insights.add("Рекомендуется планировать важные задачи на периоды хорошего настроения");
        }

        Map<String, int> moodCounts = {};
        Map<String, int> dayOfWeekCounts = {};
        int positiveDays = 0;
        int negativeDays = 0;
        for (var mood in moodsList) {
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
        String dominantMood = moodCounts.entries.isEmpty 
            ? "Нет данных" 
            : moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        int totalDays = moodsList.length;
        double positiveDaysPercentage = totalDays > 0 ? (positiveDays / totalDays) * 100 : 0.0;
        double negativeDaysPercentage = totalDays > 0 ? (negativeDays / totalDays) * 100 : 0.0;
        String mostProductiveDay = dayOfWeekCounts.isNotEmpty
            ? dayOfWeekCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : "Нет данных";

        _cachedReport = ReportModel(
          tasksThisWeek: weekCount,
          tasksThisMonth: monthCount,
          previousPeriodTasks: previousCount,
          taskChangePercentage: changePercentage,
          moodData: moodsList,
          dominantMood: dominantMood,
          positiveDaysPercentage: positiveDaysPercentage,
          negativeDaysPercentage: negativeDaysPercentage,
          categoryCounts: categoryData,
          priorityCounts: priorityData,
          moodProductivity: moodProductivity,
          mostProductiveMood: mostProductiveMood,
          mostProductiveMoodRate: mostProductiveMoodRate,
          productivityInsights: insights,
          moodChangePercentage: 0.0,
          mostProductiveDay: mostProductiveDay,
          averageTasksPerDay: averageTasksPerDay,
          mostProductiveDayForTasks: mostProductiveDayForTasks,
          totalTasksCount: weekCount + monthCount,
          taskCompletionRate: 0.0,
        );
        _dataChangedController.add(null);
      });
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Понедельник';
      case DateTime.tuesday:
        return 'Вторник';
      case DateTime.wednesday:
        return 'Среда';
      case DateTime.thursday:
        return 'Четверг';
      case DateTime.friday:
        return 'Пятница';
      case DateTime.saturday:
        return 'Суббота';
      case DateTime.sunday:
        return 'Воскресенье';
      default:
        return 'Неизвестно';
    }
  }

  void dispose() {
    _moodProductivitySubscription?.cancel();
    _tasksSubscription?.cancel();
    _moodsSubscription?.cancel();
    _dataChangedController.close();
  }
} 