import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recommendation_model.dart';
import '../services/recommendation_service.dart';
import '../../tasks/services/task_repository.dart';

class RecommendationViewModel extends ChangeNotifier {
  final RecommendationService _service = RecommendationService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  String? _currentMood;
  bool _isOnline = true;
  bool _isInitialized = false;
  StreamSubscription? _tasksSubscription;

  // Весовые коэффициенты для разных настроений
  final Map<String, Map<String, double>> moodWeights = {
    "Грусть": {
      "emotionalLoadFactor": 0.35,
      "priorityFactor": 0.30,
      "deadlineFactor": 0.10
    },
    "Радость": {
      "emotionalLoadFactor": 0.15,
      "priorityFactor": 0.25,
      "deadlineFactor": 0.35
    },
    "Спокойствие": {
      "emotionalLoadFactor": 0.20,
      "priorityFactor": 0.35,
      "deadlineFactor": 0.20
    },
    "Усталость": {
      "emotionalLoadFactor": 0.50,
      "priorityFactor": 0.15,
      "deadlineFactor": 0.10
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
      "Домашние дела": 0.6,
      "Путешествия и досуг": 0.2,
      "Другое": 0.5
    },
    "Радость": {
      "Работа": 0.7,
      "Учёба": 0.6,
      "Финансы": 0.4,
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
      "Домашние дела": 0.6,
      "Путешествия и досуг": 0.7,
      "Другое": 0.7
    },
    "Усталость": {
      "Работа": 0.1,
      "Учёба": 0.2,
      "Финансы": 0.2,
      "Здоровье и спорт": 0.6,
      "Развитие и хобби": 0.3,
      "Личное": 0.4,
      "Домашние дела": 0.8,
      "Путешествия и досуг": 0.5,
      "Другое": 0.5
    }
  };

  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentMood => _currentMood;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    if (_isInitialized) return;

    await _checkConnectivity();
    final cachedMood = await _loadMoodFromCache();
    if (cachedMood != null) {
      _currentMood = cachedMood;
      notifyListeners();
    }

    if (_isOnline) {
      await _fetchUserMood();
    }

    _initializeTasks();
  }

  void _initializeTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = TaskRepository.getTasksStream('active').listen((snapshot) {
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

      _recommendations = tasks;
      _isInitialized = true;
      notifyListeners();
    }, onError: (error) {
      _error = 'Error fetching tasks: $error';
      notifyListeners();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      notifyListeners();
    }
  }

  double _calculateEmotionalCompatibility(Map<String, dynamic> task, String mood) {
    final int load = task["emotionalLoad"] as int;

    switch (mood) {
      case "Грусть":
        return (load <= 2) ? 1.0 : (load == 3) ? 0.6 : 0.2;
      case "Радость":
        return min(pow(load / 3, 2).toDouble(), 1.0);
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
    return 1.0 - (hoursLeft / 168).clamp(0.0, 1.0);
  }

  double _calculateCategoryScore(Map<String, dynamic> task, String mood) {
    final String category = task["category"] as String;
    return categoryWeights[mood]?[category] ?? 0.5;
  }

  double _calculatePriority(Map<String, dynamic> task) {
    if (_currentMood == null) return 0.5;

    String mood = _currentMood!;
    try {
      final Map<String, dynamic> moodMap =
          (_currentMood is String && _currentMood!.startsWith('{'))
              ? json.decode(_currentMood!)
              : {'type': _currentMood};
      mood = moodMap['type'] as String;
    } catch (e) {
      mood = _currentMood!;
    }

    final weights = moodWeights[mood] ?? moodWeights["Спокойствие"]!;

    final double emotionalScore = _calculateEmotionalCompatibility(task, mood);
    final double priorityScore = _calculatePriorityScore(task, mood);
    final double deadlineScore = _calculateDeadlineScore(task);
    final double categoryScore = _calculateCategoryScore(task, mood);

    return (emotionalScore * weights["emotionalLoadFactor"]! +
        priorityScore * weights["priorityFactor"]! +
        deadlineScore * weights["deadlineFactor"]! +
        categoryScore * 0.25);
  }

  Future<void> _saveMoodToCache(String mood, DateTime timestamp, {bool synced = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('current_mood');
    if (raw != null) {
      try {
        final Map<String, dynamic> old = json.decode(raw);
        if (old['timestamp'] == timestamp.toIso8601String()) return;
      } catch (_) {}
    }
    await prefs.setString(
      'current_mood',
      json.encode({
        'type': mood,
        'timestamp': timestamp.toIso8601String(),
        'synced': synced,
      }),
    );
  }

  Future<String?> _loadMoodFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('current_mood');
    if (raw == null) return null;

    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final ts = DateTime.parse(data['timestamp']);
      final now = DateTime.now();
      if (ts.year == now.year && ts.month == now.month && ts.day == now.day) {
        return data['type'] as String;
      }
    } catch (_) {}
    await prefs.remove('current_mood');
    return null;
  }

  Future<void> _clearMoodCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_mood');
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
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final serverMood = doc['type'] as String;
        final ts = (doc['timestamp'] as Timestamp).toDate();

        await _saveMoodToCache(serverMood, ts, synced: true);
        _currentMood = serverMood;
        notifyListeners();
      } else {
        await _clearMoodCache();
        _currentMood = null;
        notifyListeners();
      }
    } catch (e) {
      print('Ошибка получения настроения: $e');
      final cachedMood = await _loadMoodFromCache();
      if (cachedMood != null) {
        _currentMood = cachedMood;
        notifyListeners();
      }
    }
  }

  Future<void> loadRecommendations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendations = (await _service.getRecommendations()).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendationsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendations = (await _service.getRecommendationsByCategory(category)).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecommendation(RecommendationModel recommendation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addRecommendation(recommendation);
      await loadRecommendations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRecommendation(String id, RecommendationModel recommendation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateRecommendation(id, recommendation);
      await loadRecommendations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRecommendation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteRecommendation(id);
      await loadRecommendations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 