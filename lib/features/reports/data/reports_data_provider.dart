import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/features/tasks/services/task_repository.dart';

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
  int totalTasksCount = 0;
  double taskCompletionRate = 0.0;

  bool _isInitialized = false;
  Map<String, Map<String, dynamic>> _periodCache = {};

  StreamSubscription? _moodProductivitySubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _moodsSubscription;

  bool get isInitialized => _isInitialized;

  bool hasCachedData(String period) => _periodCache.containsKey(period);

  Future<void> initialize(String period) async {
    selectedPeriod = period;
    
    // Отменяем предыдущие подписки перед новой инициализацией
    _moodProductivitySubscription?.cancel();
    _tasksSubscription?.cancel();
    _moodsSubscription?.cancel();

    // Создаем Completer для каждого потока данных
    final taskCompleter = Completer<void>();
    final moodCompleter = Completer<void>();
    final productivityCompleter = Completer<void>();

    // Инициализируем потоки данных
    await _fetchTaskCounts(taskCompleter);
    await _fetchMoodHistory(moodCompleter);
    await _fetchMoodProductivity(productivityCompleter);

    // Ждем завершения всех операций
    await Future.wait([
      taskCompleter.future,
      moodCompleter.future,
      productivityCompleter.future,
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
    totalTasksCount = cachedData['totalTasksCount'];
    taskCompletionRate = cachedData['taskCompletionRate'];
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
      'totalTasksCount': totalTasksCount,
      'taskCompletionRate': taskCompletionRate,
      'productivityInsights': productivityInsights,
    };
  }

  Future<void> _fetchTaskCounts(Completer<void> completer) async {
    User? user = TaskRepository.getCurrentUser();
    if (user == null) {
      completer.complete();
      return;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime startDate = selectedPeriod == "Неделя"
        ? today.subtract(Duration(days: 7))
        : today.subtract(Duration(days: 30));
    DateTime previousPeriodStart = selectedPeriod == "Неделя"
        ? startDate.subtract(Duration(days: 7))
        : startDate.subtract(Duration(days: 30));

    _tasksSubscription = TaskRepository.getTasksStream("completed").listen(
      (snapshot) {
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
            
            if (completionDate.isAfter(startDate)) {
              if (selectedPeriod == "Неделя") {
                weekCount++;
              } else {
                monthCount++;
              }

              String dayName = getDayName(completionDate.weekday);
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

        int currentPeriodTasks = selectedPeriod == "Неделя" ? weekCount : monthCount;
        double changePercentage = previousCount > 0 
            ? ((currentPeriodTasks - previousCount) / previousCount) * 100 
            : 0.0;

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
        
        _saveToCache();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        print('Error fetching task counts: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
  }

  Future<void> _fetchMoodHistory(Completer<void> completer) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      completer.complete();
      return;
    }

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    _moodsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        List<Map<String, dynamic>> moods = [];
        List<Map<String, dynamic>> moodDataList = [];

        for (var doc in snapshot.docs) {
          DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
          if (timestamp.isAfter(startDate)) {
            moods.add({
              "date": timestamp,
              "mood": doc['type'],
            });
            
            moodDataList.add({
              "date": timestamp,
              "mood": doc['type'],
              "note": doc['note'],
            });
          }
        }

        moodData = moodDataList;
        _calculateMoodStatistics(moods);
        _saveToCache();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        print('Error fetching mood history: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
  }

  Future<void> _fetchMoodProductivity(Completer<void> completer) async {
    User? user = TaskRepository.getCurrentUser();
    if (user == null) {
      completer.complete();
      return;
    }

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    Stream<QuerySnapshot> tasksStream = TaskRepository.getTasksStream("completed");
    Stream<QuerySnapshot> moodsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .snapshots();

    _moodProductivitySubscription = tasksStream.listen(
      (tasksSnapshot) {
        moodsStream.listen(
          (moodsSnapshot) {
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

            moodDays.forEach((mood, days) {
              if (days > 0) {
                productivityRates[mood] = (counts[mood] ?? 0) / days;
              }
            });

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
                if (difference > 1) {
                  insights.add("Разница в продуктивности между лучшим и худшим настроением: ${difference.toStringAsFixed(1)} задач в день");
                }
              }
            }

            if (mostProductiveMood == "Радость" || mostProductiveMood == "Спокойствие") {
              insights.add("Рекомендуется планировать важные задачи на периоды хорошего настроения");
            } else if (counts.containsKey("Усталость") && (counts["Усталость"] ?? 0) > 0) {
              insights.add("При усталости лучше делать небольшие, простые задачи");
            }

            moodProductivity = counts;
            productivityInsights = insights;
            _saveToCache();
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (error) {
            print('Error in mood stream: $error');
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
      },
      onError: (error) {
        print('Error in tasks stream: $error');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
  }

  void _calculateMoodStatistics(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) {
      dominantMood = "Нет данных";
      positiveDaysPercentage = 0.0;
      negativeDaysPercentage = 0.0;
      moodChangePercentage = 0.0;
      mostProductiveDay = "Нет данных";
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
      String dayName = getDayName(date.weekday);
      
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

    dominantMood = mostCommonMood;
    positiveDaysPercentage = currentPositivePercentage;
    negativeDaysPercentage = totalDays > 0 ? (negativeDays / totalDays) * 100 : 0.0;
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