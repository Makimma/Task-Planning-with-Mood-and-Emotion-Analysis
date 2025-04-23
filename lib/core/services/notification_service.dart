import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_appp/features/tasks/services/task_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await AwesomeNotifications().cancelAll();
      print("🔕 Уведомления отключены, все удалены");
    } else {
      final tasks = await TaskRepository.getTasksByStatus("active");
      for (final task in tasks.docs) {
        final id = task.id.hashCode;
        final reminderOffset = task['reminderOffset'] ?? 0;
        final deadline = (task['deadline'] as Timestamp).toDate();
        final title = task['title'];

        if (reminderOffset > 0) {
          await NotificationService.scheduleReminder(
            id: id,
            title: title,
            reminderTime: deadline.subtract(Duration(minutes: reminderOffset)),
          );
        }
        print('🧪 Готовим уведомление для: $title');
      }
      print("🔔 Уведомления включены и пересозданы");
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime reminderTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'task_channel',
        title: 'Напоминание о задаче',
        body: title,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: reminderTime, preciseAlarm: true),
    );
  }

  static Future<void> cancelReminder(int id) async {
    await AwesomeNotifications().cancel(id);
    print('🔕 Уведомление удалено: $id');
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
