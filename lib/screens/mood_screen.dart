import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../services/nlp_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/gradient_mood_icon.dart';

class MoodScreen extends StatefulWidget {
  @override
  _MoodScreenState createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  String selectedMood = "";
  String note = "";
  String currentMood = "Настроение не выбрано";
  bool isOnline = true;
  bool _isInitialized = false;
  StreamSubscription? _moodSubscription;

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
    _moodSubscription?.cancel();
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
    await _loadLocalMood();
    
    if (isOnline) {
      await _syncOfflineMoods();
      _initializeMoodStream();
    } else {
      setState(() {
        _isInitialized = true;
      });
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

  void _initializeMoodStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _moodSubscription?.cancel();
    _moodSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moods")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty && mounted) {
        final serverMood = snapshot.docs.first["type"];
        final serverNote = snapshot.docs.first["note"] ?? "";
        
        await _saveLocalMood(serverMood, serverNote);
        
        if (mounted) {
          setState(() {
            currentMood = serverMood;
            _isInitialized = true;
          });
        }
      }
    }, onError: (error) {
      print('Error in mood stream: $error');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
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
          .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Настроение",
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
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
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
                            mood: currentMood,
                            size: 40,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentMood.isEmpty ? "Настроение не выбрано" : currentMood,
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
                SizedBox(height: 24),
                Text(
                  "Выберите ваше настроение",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 12),
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
                SizedBox(height: 24),
                Text(
                  "Текстовая заметка",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    maxLength: 512,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      hintText: "Опишите, что повлияло на ваше настроение...",
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        note = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveMood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Сохранить",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
