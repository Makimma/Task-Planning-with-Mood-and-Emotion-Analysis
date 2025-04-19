import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../services/nlp_service.dart';
import '../widgets/mood_selector.dart';

class MoodScreen extends StatefulWidget {
  @override
  _MoodScreenState createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with WidgetsBindingObserver {
  String selectedMood = "";
  String note = "";
  String currentMood = "Настроение не выбрано";
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  Future<void> _initializeScreen() async {
    await _checkConnectivity();
    await _loadLocalMood();
    if (isOnline) {
        // Сначала пробуем синхронизировать локальные изменения
        await _syncOfflineMoods();
        // Только после этого загружаем с сервера
        await _loadServerMood();
    }
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

  Future<void> _saveLocalMood(String mood, String note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodData = {
        'type': mood,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };
      await prefs.setString('current_mood', json.encode(moodData));
    } catch (e) {
      print('Ошибка сохранения локального настроения: $e');
    }
  }

  Future<Map<String, dynamic>?> _getLocalMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodString = prefs.getString('current_mood');
      if (moodString != null) {
        return json.decode(moodString);
      }
    } catch (e) {
      print('Ошибка получения локального настроения: $e');
    }
    return null;
  }

  Future<void> _loadLocalMood() async {
    try {
      final localMood = await _getLocalMood();
      if (mounted) {
        setState(() {
          currentMood = localMood?['type'] ?? "Настроение не выбрано";
        });
      }
    } catch (e) {
      print('Ошибка загрузки локального настроения: $e');
    }
  }

  Future<void> _loadServerMood() async {
    try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Проверяем, нет ли несинхронизированных изменений
        final localMood = await _getLocalMood();
        if (localMood != null && localMood['synced'] == false) {
            // Если есть несинхронизированные изменения, не загружаем с сервера
            return;
        }

        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
        DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        QuerySnapshot moodSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("moods")
            .where("timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        if (moodSnapshot.docs.isNotEmpty && mounted) {
            final serverMood = moodSnapshot.docs.first["type"];
            await _saveLocalMood(serverMood, moodSnapshot.docs.first["note"] ?? "");
            
            setState(() {
                currentMood = serverMood;
            });
        }
    } catch (e) {
        print('Ошибка загрузки серверного настроения: $e');
    }
  }

  Future<void> _syncOfflineMoods() async {
    if (!isOnline) return;

    try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final localMood = await _getLocalMood();
        if (localMood == null || localMood['synced'] == true) return;

        DateTime now = DateTime.now();
        DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
        DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

        QuerySnapshot moodSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("moods")
            .where("timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        if (moodSnapshot.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .collection("moods")
                .doc(moodSnapshot.docs.first.id)
                .update({
                    "type": localMood['type'],
                    "note": localMood['note'],
                    "timestamp": Timestamp.fromDate(DateTime.parse(localMood['timestamp'])),
                });
        } else {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .collection("moods")
                .add({
                    "type": localMood['type'],
                    "note": localMood['note'],
                    "timestamp": Timestamp.fromDate(DateTime.parse(localMood['timestamp'])),
                });
        }

        final updatedMoodData = {
            ...localMood,
            'synced': true,
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_mood', json.encode(updatedMoodData));

        if (mounted) {
            setState(() {
                currentMood = localMood['type'];
            });
        }
    } catch (e) {
        print('Ошибка синхронизации: $e');
    }
  }

  void _saveMood() async {
    if (!mounted) return;
    
    await _checkConnectivity();

    // Если нет интернета и пытаемся определить настроение автоматически
    if (selectedMood.isEmpty && note.isNotEmpty && !isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Для автоматического определения настроения требуется подключение к интернету. Пожалуйста, выберите настроение вручную.")),
      );
      return;
    }

    // Определяем настроение только если есть интернет
    if (selectedMood.isEmpty && note.isNotEmpty && isOnline) {
      try {
        if (!mounted) return;

        Map<String, double>? sentimentResult =
            await NaturalLanguageService.analyzeSentiment(note);
        if (!mounted) return;
        
        if (sentimentResult != null) {
          double score = sentimentResult["score"]!;
          double magnitude = sentimentResult["magnitude"]!;
          selectedMood = _mapSentimentToMood(score, magnitude);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка анализа настроения. Пожалуйста, выберите настроение вручную.")),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка анализа настроения. Пожалуйста, выберите настроение вручную.")),
        );
        return;
      }
    }

    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Выберите настроение перед сохранением!")),
      );
      return;
    }

    // Сохраняем локально
    await _saveLocalMood(selectedMood, note);

    // Пробуем синхронизировать с сервером
    if (isOnline) {
      await _syncOfflineMoods();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Настроение сохранено и синхронизировано!")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Настроение сохранено локально и будет синхронизировано при появлении сети")),
      );
    }

    if (!mounted) return;
    setState(() {
      currentMood = selectedMood;
      selectedMood = "";
      note = "";
    });
  }

  String _mapSentimentToMood(double score, double magnitude) {
    if (score < -0.5 && magnitude >= 1.0) {
      return "Грусть";
    }
    if (score >= 0.5 && magnitude < 3.0) {
      return "Радость";
    }
    if (score <= -0.3 && magnitude >= 0.5 && magnitude < 1.5) {
      return "Усталость";
    }
    return "Спокойствие";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настроение")),
      body: RefreshIndicator(
        onRefresh: _initializeScreen,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Текущее настроение:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 5),
                Card(
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.mood, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          currentMood.isEmpty ? "Настроение не выбрано" : currentMood,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("Выберите ваше настроение:",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                MoodSelector(
                  selectedMood: selectedMood,
                  onMoodSelected: (mood) {
                    setState(() {
                      if (selectedMood == mood) {
                        selectedMood = ""; // Снимаем выбор, если нажали повторно
                      } else {
                        selectedMood = mood;
                      }
                    });
                  },
                ),
                SizedBox(height: 20),
                TextField(
                  maxLength: 512,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Текстовая заметка",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      note = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveMood,
                    child: Text("Сохранить"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
