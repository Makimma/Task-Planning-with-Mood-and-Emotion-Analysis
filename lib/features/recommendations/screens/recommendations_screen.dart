import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:flutter_appp/features/tasks/services/task_actions.dart';
import 'package:flutter_appp/features/tasks/widgets/task_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appp/features/tasks/services/task_repository.dart';

import '../../moods/widgets/gradient_mood_icon.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  String? currentMood;
  bool isOnline = true;
  List<Map<String, dynamic>> cachedTasks = [];
  bool _isInitialized = false;
  StreamSubscription? _tasksSubscription;

  // Весовые коэффициенты для разных настроений
  final Map<String, Map<String, double>> moodWeights = {
    "Грусть": {
      "emotionalLoadFactor": 0.15,
      "priorityFactor": 0.35,
      "deadlineFactor": 0.25
    },

    "Радость": {
      "emotionalLoadFactor": 0.15,
      "priorityFactor": 0.3,
      "deadlineFactor": 0.3
    },

    "Спокойствие": {
      "emotionalLoadFactor": 0.15,
      "priorityFactor": 0.3,
      "deadlineFactor": 0.3
    },

    "Усталость": {
      "emotionalLoadFactor": 0.25,
      "priorityFactor": 0.3,
      "deadlineFactor": 0.2
    }
  };

  // Веса категорий для разных настроений
  final Map<String, Map<String, double>> categoryWeights = {
    "Грусть": {
      "Работа": 0.9,
      "Учёба": 0.8,
      "Финансы": 0.9,
      "Здоровье и спорт": 0.4,
      "Развитие и хобби": 0.5,
      "Личное": 0.3,
      "Домашние дела": 0.7,
      "Путешествия и досуг": 0.2,
      "Другое": 0.5
    },
    "Радость": {
      "Работа": 0.7,
      "Учёба": 0.6,
      "Финансы": 0.5,
      "Здоровье и спорт": 0.9,
      "Развитие и хобби": 0.9,
      "Личное": 0.9,
      "Домашние дела": 0.6,
      "Путешествия и досуг": 1.0,
      "Другое": 0.7
    },
    "Спокойствие": {
      "Работа": 1.0,
      "Учёба": 1.0,
      "Финансы": 0.9,
      "Здоровье и спорт": 0.8,
      "Развитие и хобби": 0.8,
      "Личное": 0.8,
      "Домашние дела": 0.7,
      "Путешествия и досуг": 0.7,
      "Другое": 0.7
    },
    "Усталость": {
      "Работа": 0.3,
      "Учёба": 0.2,
      "Финансы": 0.2,
      "Здоровье и спорт": 0.4,
      "Развитие и хобби": 0.3,
      "Личное": 0.4,
      "Домашние дела": 0.8,
      "Путешествия и досуг": 0.5,
      "Другое": 0.5
    }
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tasksSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  double _calculateEmotionalCompatibility(Map<String, dynamic> task, String mood) {
    final int load = task["emotionalLoad"] as int;
    
    switch(mood) {
      case "Грусть":
        return 1 - (load / 5);
      
      case "Радость":
        return load / 5;
      
      case "Спокойствие":
        return 1 - (pow(load - 3, 2) / 4).toDouble();
      
      case "Усталость":
        return load <= 2 ? 1.0 : 0.0;
      
      default:
        return 0.5;
    }
  }

  double _calculatePriorityScore(Map<String, dynamic> task, String mood) {
    final Map<String, double> priorityValues = {
      "low": 0.3,
      "medium": 0.6,
      "high": 1.0
    };
    
    return priorityValues[task["priority"]] ?? 0.3;
  }

  double _calculateDeadlineScore(Map<String, dynamic> task) {
    final DateTime now = DateTime.now();
    final DateTime deadline = (task["deadline"] as Timestamp).toDate();
    final double hoursLeft = deadline.difference(now).inHours.toDouble();
    
    if (hoursLeft <= 24) return 1.0;
    if (hoursLeft <= 48) return 0.8;
    if (hoursLeft <= 72) return 0.6;
    if (hoursLeft <= 168) return 0.4;
    return 0.2;
  }

  double _calculateCategoryScore(Map<String, dynamic> task, String mood) {
    final String category = task["category"] as String;
    return categoryWeights[mood]?[category] ?? 0.5;
  }

  double _calculatePriority(Map<String, dynamic> task) {
    if (currentMood == null) return 0.5;

    String mood = currentMood!;
    try {
      final Map<String, dynamic> moodMap = 
          (currentMood is String && currentMood!.startsWith('{')) 
              ? json.decode(currentMood!) 
              : {'type': currentMood};
      mood = moodMap['type'] as String;
    } catch (e) {
      mood = currentMood!;
    }

    final weights = moodWeights[mood] ?? moodWeights["Спокойствие"]!;
    
    final double emotionalScore = _calculateEmotionalCompatibility(task, mood);
    final double priorityScore = _calculatePriorityScore(task, mood);
    final double deadlineScore = _calculateDeadlineScore(task);
    final double categoryScore = _calculateCategoryScore(task, mood);
    
    return (
      emotionalScore * weights["emotionalLoadFactor"]! +
      priorityScore * weights["priorityFactor"]! +
      deadlineScore * weights["deadlineFactor"]! +
      categoryScore * 0.25
    );
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    await _checkConnectivity();
    final cachedMood = await _loadMoodFromCache();
    if (cachedMood != null && mounted) {
      setState(() {
        currentMood = cachedMood;
      });
    }

    if (isOnline) {
      await _fetchUserMood();
    }

    _initializeTasks();
  }

  void _initializeTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = TaskRepository.getTasksStream('active').listen((snapshot) {
      if (!mounted) return;

      List<Map<String, dynamic>> tasks = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      tasks.sort((a, b) {
        final priorityA = _calculatePriority(a);
        final priorityB = _calculatePriority(b);
        return priorityB.compareTo(priorityA);
      });

      setState(() {
        cachedTasks = tasks;
        _isInitialized = true;
      });
    }, onError: (error) {
      print('Error fetching tasks: $error');
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      setState(() {
        isOnline = connectivityResult != ConnectivityResult.none;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isOnline = false;
      });
    }
  }

  Future<void> _saveMoodToCache(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_mood', mood);
  }

  Future<String?> _loadMoodFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final moodData = prefs.getString('current_mood');
    if (moodData != null) {
      try {
        final Map<String, dynamic> moodMap = json.decode(moodData);
        return moodMap['type'] as String;
      } catch (e) {
        return moodData;
      }
    }
    return null;
  }

  Future<void> _fetchUserMood() async {
    try {
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

      if (snapshot.docs.isNotEmpty && mounted) {
        final serverMood = snapshot.docs.first['type'];
        await _saveMoodToCache(serverMood);
        setState(() {
          currentMood = serverMood;
        });
      }
    } catch (e) {
      print('Ошибка получения настроения: $e');
      final cachedMood = await _loadMoodFromCache();
      if (cachedMood != null && mounted) {
        setState(() {
          currentMood = cachedMood;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Рекомендации",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _isInitialized = false;
          await _initializeScreen();
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentMood == null)
                Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Укажите ваше настроение, чтобы получать более точные рекомендации.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (currentMood != null) ...[
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
                        "Текущее настроение",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          GradientMoodIcon(
                            mood: currentMood!,
                            size: 40,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentMood!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),
              Text(
                "Рекомендуемые задачи",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    if (cachedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Нет активных задач",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: cachedTasks.length,
      itemBuilder: (context, index) {
        final task = cachedTasks[index];

        return Dismissible(
          key: Key(task['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Удалить',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await TaskActions.showDeleteConfirmation(context, task['id']);
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TaskCard(
              task: task,
              isCompleted: false,
              onEdit: () => TaskActions.showEditTaskDialog(context, task),
              onComplete: () => TaskActions.completeTask(task['id'], context),
            ),
          ),
        );
      },
    );
  }
}
