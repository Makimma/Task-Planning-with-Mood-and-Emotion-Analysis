import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }
    return user;
  }

  static String? _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return user.uid;
  }

  static Future<void> deleteTask(String taskId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
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

  static Future<void> updateTask({
    required String taskId,
    required String title,
    required String comment,
    required String category,
    required String priority,
    required int emotionalLoad,
    required DateTime deadline,
    required int reminderOffset,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
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
        'reminderOffset': reminderOffset,
      });
    } catch (e) {
      throw Exception('Ошибка обновления задачи: $e');
    }
  }

  static Future<void> completeTask(String taskId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
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

  static Future<DocumentReference> addTask({
    required String title,
    required String comment,
    required String category,
    required String priority,
    required int emotionalLoad,
    required DateTime deadline,
    required int reminderOffsetMinutes,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      return await _firestore
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
        'reminderOffset': reminderOffsetMinutes,
      });
    } catch (e) {
      throw Exception('Ошибка создания задачи: $e');
    }
  }

  static Stream<QuerySnapshot> getTasksStream(String status) {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  static Future<QuerySnapshot> getTasksByStatus(String status) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    return await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: status)
        .get();
  }

  static Stream<QuerySnapshot> getAllTasksStream() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

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
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    return await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where(field, isEqualTo: value)
        .limit(limit)
        .get();
  }
}