import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mood_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/nlp_service.dart';
import '../models/mood_model.dart';

enum MoodState { idle, loading, success, error }

class MoodViewModel extends ChangeNotifier {
  final MoodService _service;
  MoodModel? currentMood;
  List<MoodModel> history = [];
  MoodState state = MoodState.idle;
  String? errorMessage;
  String selectedType = '';
  String note = '';
  bool isOnline = true;
  bool _isInitialized = false;

  MoodViewModel({required SharedPreferences prefs})
      : _service = MoodService(prefs: prefs);

  Future<void> init() async {
    if (_isInitialized) return;
    
    state = MoodState.loading;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Load local mood immediately
      currentMood = _service.getLocalMood();
      state = MoodState.success;
      notifyListeners();

      // Subscribe to full mood stream
      if (user != null) {
        final conn = await Connectivity().checkConnectivity();
        final isOnline = conn != ConnectivityResult.none;

        // Если есть интернет и есть локальное несинхронизированное настроение - синхронизируем
        if (isOnline && currentMood != null && !currentMood!.synced) {
          await _service.syncMood(currentMood!, user.uid);
          currentMood = currentMood!.copyWith(synced: true);
          await _service.saveLocalMood(currentMood!);
        }

        _service.moodStream(user.uid).listen((list) async {
          history = list;

          // Sync local if unsynced
          final local = _service.getLocalMood();
          if (local != null && !local.synced) {
            await _service.saveLocalMood(local.copyWith(synced: true));
            await _service.syncMood(local, user.uid);
          }

          if (history.isNotEmpty) {
            // Find the most recent mood by timestamp
            final latest = history.reduce((a, b) =>
                a.timestamp.isAfter(b.timestamp) ? a : b);
            // Update only if newer than current
            if (currentMood == null ||
                latest.timestamp.isAfter(currentMood!.timestamp)) {
              currentMood = latest;
              state = MoodState.success;
              notifyListeners();
            }
          }
        });
      }

      _isInitialized = true;
      state = MoodState.success;
      notifyListeners();
    } catch (e) {
      state = MoodState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      isOnline = connectivityResult != ConnectivityResult.none;
      notifyListeners();
    } catch (e) {
      isOnline = false;
      notifyListeners();
    }
  }

  void selectMood(String type) {
    selectedType = (selectedType == type) ? '' : type;
    notifyListeners();
  }

  void setNote(String text) {
    note = text;
    notifyListeners();
  }

  Future<void> saveMood() async {
    state = MoodState.loading;
    notifyListeners();

    // Auto-detect mood from note if present
    if (selectedType.isEmpty && note.isNotEmpty) {
      try {
        String? result = await NaturalLanguageService.analyzeMood(note);
        if (result != null && result.isNotEmpty) selectedType = result;
      } catch (_) {}
    }

    if (selectedType.isEmpty) {
      errorMessage = 'Выберите настроение перед сохранением';
      state = MoodState.error;
      notifyListeners();
      return;
    }

    final mood = MoodModel(
      type: selectedType,
      note: note.isEmpty ? null : note,
      timestamp: DateTime.now(),
      synced: false,
    );

    try {
      await _service.saveLocalMood(mood);
      await _checkConnectivity();

      final user = FirebaseAuth.instance.currentUser;
      if (isOnline && user != null) {
        // Sync with server when online
        await _service.syncMood(mood, user.uid);
        mood.synced;
        currentMood = mood.copyWith(synced: true);
      } else {
        // Offline: update current immediately
        currentMood = mood;
      }

      selectedType = '';
      note = '';

      state = MoodState.success;
      notifyListeners();
    } catch (e) {
      state = MoodState.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
