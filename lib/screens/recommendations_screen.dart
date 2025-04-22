import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_appp/services/task_repository.dart';

import '../widgets/gradient_mood_icon.dart';

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

  Future<void> _saveTasksToCache(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(tasks.map((task) {
      return {
        ...task,
        'deadline': (task['deadline'] as Timestamp).toDate().toIso8601String(),
      };
    }).toList());
    await prefs.setString('cached_tasks', tasksJson);
  }

  Future<void> _loadCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString('cached_tasks');
      if (tasksString != null) {
        final List<dynamic> decodedTasks = json.decode(tasksString);
        if (!mounted) return;
        setState(() {
          cachedTasks = decodedTasks.map((task) {
            return {
              ...task,
              'deadline': Timestamp.fromDate(DateTime.parse(task['deadline'])),
            };
          }).cast<Map<String, dynamic>>().toList();
        });
      }
    } catch (e) {
      print('Ошибка загрузки кэшированных задач: $e');
    }
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

  double _calculatePriority(Map<String, dynamic> task) {
    DateTime now = DateTime.now();
    DateTime deadline = (task["deadline"] as Timestamp).toDate();

    double deadlineFactor = 1 / ((deadline.difference(now).inHours + 1).toDouble());
    double emotionalLoadFactor = _getEmotionalLoadFactor(task["emotionalLoad"]);

    Map<String, double> priorityMap = {"high": 1.0, "medium": 0.7, "low": 0.3};
    double priorityFactor = priorityMap[task["priority"]] ?? 0.3;

    return (deadlineFactor * 0.5) + (emotionalLoadFactor * 0.3) + (priorityFactor * 0.2);
  }

  double _getEmotionalLoadFactor(int load) {
    String? moodType = currentMood;
    if (currentMood != null) {
      try {
        final Map<String, dynamic> moodMap = 
            (currentMood is String && currentMood!.startsWith('{')) 
                ? json.decode(currentMood!) 
                : {'type': currentMood};
        moodType = moodMap['type'] as String;
      } catch (e) {
        moodType = currentMood;
      }
    }

    double factor = 0.5;

    if (moodType == "Радость") {
      factor = load / 5;
    } else if (moodType == "Спокойствие") {
      factor = 1 - (pow(load - 3, 2) / 4).toDouble();
    } else if (moodType == "Грусть") {
      factor = (5 - load) / 4;
    } else if (moodType == "Усталость") {
      factor = ((pow(5 - load, 2) + 4) / 20).toDouble();
    }

    return factor;
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
