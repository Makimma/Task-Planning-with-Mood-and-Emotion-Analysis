import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'gradient_mood_icon.dart';

class MoodHistory extends StatefulWidget {
  final bool isOnline;

  const MoodHistory({Key? key, required this.isOnline}) : super(key: key);

  @override
  State<MoodHistory> createState() => MoodHistoryState();
}

class MoodHistoryState extends State<MoodHistory> {
  List<Map<String, dynamic>> _offlineMoods = [];
  List<Map<String, dynamic>> _cachedOnlineMoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOfflineMoods();
    _loadHistoryCache();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadHistoryCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mood_history');
    if (raw != null) {
      try {
        final List data = json.decode(raw);
        setState(() {
          _cachedOnlineMoods = data
              .map<Map<String, dynamic>>((e) => {
                    'type': e['type'],
                    'note': e['note'],
                    'timestamp': DateTime.parse(e['timestamp']),
                  })
              .toList();
        });
      } catch (_) {
        /* ignore */
      }
    }
  }

  Future<void> _saveHistoryCache(List<Map<String, dynamic>> moods) async {
    final prefs = await SharedPreferences.getInstance();
    final serialised = moods
        .map((e) => {
              'type': e['type'],
              'note': e['note'],
              'timestamp': (e['timestamp'] as DateTime).toIso8601String(),
            })
        .toList();
    await prefs.setString('mood_history', json.encode(serialised));
  }

  Future<void> loadOfflineMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moodString = prefs.getString('current_mood');
      setState(() {
        _isLoading = false;
        if (moodString != null) {
          final moodData = json.decode(moodString);
          final timestamp = DateTime.parse(moodData['timestamp']);
          final now = DateTime.now();
          // Check if the mood is from today
          if (timestamp.year == now.year &&
              timestamp.month == now.month &&
              timestamp.day == now.day) {
            final newEntry = {
              'type': moodData['type'],
              'note': moodData['note'],
              'timestamp': timestamp,
            };
            final current = [..._cachedOnlineMoods];

            current.removeWhere(
                (e) => _isSameDay(e['timestamp'] as DateTime, timestamp));

            current.insert(0, newEntry);

            _offlineMoods = current;
            _cachedOnlineMoods = current;
            _saveHistoryCache(current);
          } else {
            _offlineMoods = [];
          }
        } else {
          _offlineMoods = [];
        }
      });
    } catch (e) {
      print('Ошибка загрузки локального настроения: $e');
      setState(() {
        _isLoading = false;
        _offlineMoods = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если нет подключения к интернету, показываем локальные данные
    if (!widget.isOnline) {
      final moods =
          _offlineMoods.isNotEmpty ? _offlineMoods : _cachedOnlineMoods;
      return _buildMoodList(moods);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getMoodHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // В случае ошибки показываем локальные данные
          return _buildMoodList(_offlineMoods);
        }

        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final onlineMoods = snapshot.data?.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'type': data['type'],
                'note': data['note'],
                'timestamp': (data['timestamp'] as Timestamp).toDate(),
              };
            }).toList() ??
            [];

        // Объединяем онлайн-список с тем, что накоплено локально
        List<Map<String, dynamic>> merged = [...onlineMoods];
        for (final local in _offlineMoods) {
          final tsLocal = local['timestamp'] as DateTime;
          final exists = merged.any(
              (e) => (e['timestamp'] as DateTime).isAtSameMomentAs(tsLocal));
          if (!exists) merged.insert(0, local); // вставляем «свежак» в начало
        }

        // ️Обновляем кеш только если что-то изменилось
        if (merged.isNotEmpty) {
          _cachedOnlineMoods = merged;
          _saveHistoryCache(merged);
        }

        // оставляем только первую запись на каждый день
        final Map<String, Map<String, dynamic>> uniqueByDay = {};
        for (final e in merged) {
          final dt = e['timestamp'] as DateTime;
          final key = '${dt.year}-${dt.month}-${dt.day}';
          uniqueByDay.putIfAbsent(key, () => e);
        }

        final moods = uniqueByDay.values.toList();

        return _buildMoodList(moods);
      },
    );
  }

  Widget _buildMoodList(List<Map<String, dynamic>> moods) {
    if (moods.isEmpty) {
      return Center(
        child: Text(
          'История настроений пуста',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: moods.length,
      itemBuilder: (context, index) {
        final mood = moods[index];
        final timestamp = mood['timestamp'] as DateTime;
        final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(timestamp);

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GradientMoodIcon(
                mood: mood['type'],
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood['type'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (mood['note'] != null &&
                        mood['note'].toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          mood['note'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getMoodHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moods")
        .orderBy("timestamp", descending: true)
        .limit(10)
        .snapshots();
  }
}
