import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_model.dart';

class MoodService {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  MoodService({required SharedPreferences prefs, FirebaseFirestore? firestore})
      : _prefs = prefs,
        _firestore = firestore ?? FirebaseFirestore.instance;

  MoodModel? getLocalMood() {
    final jsonString = _prefs.getString('current_mood');
    if (jsonString == null) return null;
    final moodData = json.decode(jsonString);
    final timestamp = DateTime.parse(moodData['timestamp']);
    final now = DateTime.now();
    // Check if the mood is from today
    if (timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day) {
      return MoodModel.fromJson(moodData);
    }
    return null;
  }

  Future<void> saveLocalMood(MoodModel mood) async {
    await _prefs.setString('current_mood', json.encode(mood.toJson()));
  }

  Stream<List<MoodModel>> moodStream(String uid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MoodModel.fromJson({...d.data(), 'synced': true}))
            .toList());
  }

  Future<void> syncMood(MoodModel mood, String uid) async {
    final col = _firestore.collection('users').doc(uid).collection('moods');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await col
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final data = {
      'type': mood.type,
      'note': mood.note,
      'timestamp': Timestamp.fromDate(mood.timestamp),
    };

    if (snapshot.docs.isEmpty) {
      // Если нет настроения за сегодня, создаем новое
      await col.add(data);
    } else {
      await col.doc(snapshot.docs.first.id).update(data);
    }
  }
}