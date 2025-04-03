import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }
    return user;
  }

  static String _getCurrentUserId() {
    return getCurrentUser().uid;
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления задачи: $e');
    }
  }

  static Future<void> updateTask({required String taskId, required String title, required String comment, required String category, required String priority, required int emotionalLoad, required DateTime deadline,}) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'title': title,
        'comment': comment,
        'category': category,
        'priority': priority,
        'emotionalLoad': emotionalLoad,
        'deadline': Timestamp.fromDate(deadline),
      });
    } catch (e) {
      throw Exception('Ошибка обновления задачи: $e');
    }
  }

  static Future<void> completeTask(String taskId) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Ошибка завершения задачи: $e');
    }
  }

  static Future<void> addTask({required String title, required String comment, required String category, required String priority, required int emotionalLoad, required DateTime deadline,}) async {
    try {
      final userId = _getCurrentUserId();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add({
        'title': title,
        'comment': comment,
        'category': category,
        'priority': priority,
        'emotionalLoad': emotionalLoad,
        'deadline': Timestamp.fromDate(deadline),
        'status': 'active',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Ошибка создания задачи: $e');
    }
  }

  static Stream<QuerySnapshot> getTasksStream(String status) {
    final userId = _getCurrentUserId();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  static Future<QuerySnapshot> getTasksByStatus(String status) {
      final userId = _getCurrentUserId();
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('status', isEqualTo: status)
          .get();
  }

  static Stream<QuerySnapshot> getAllTasksStream() {
    final userId = _getCurrentUserId();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots();
  }

  static Future<QuerySnapshot> queryTasks({
    required String field,
    required dynamic value,
    int limit = 100,
  }) {
    final userId = _getCurrentUserId();
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where(field, isEqualTo: value)
        .limit(limit)
        .get();
  }
}