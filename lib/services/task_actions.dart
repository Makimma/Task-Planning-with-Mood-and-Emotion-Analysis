import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/task_constants.dart';
import 'task_repository.dart';
import 'notification_service.dart';

class TaskActions {
  static final User? user = TaskRepository.getCurrentUser();

  static Future<bool?> showDeleteConfirmation(
      BuildContext context, String taskId) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Удалить задачу?"),
          content: Text(
              "Вы уверены, что хотите удалить эту задачу? Действие нельзя отменить."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Отмена
              child: Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  TaskActions.deleteTask(context, taskId);
                } finally {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Удалить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static void showEditTaskDialog(
      BuildContext context, Map<String, dynamic> task) {
    final _formKey = GlobalKey<FormState>();
    String title = task['title'];
    String comment = task['comment'] ?? "";
    String category = task['category'];
    String priority = task['priority'];
    int emotionalLoad = task['emotionalLoad'];
    DateTime deadline = (task['deadline'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Редактировать задачу"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: title,
                      decoration: InputDecoration(labelText: "Название"),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Название обязательно";
                        } else if (value.length > 50) {
                          return "Максимум 50 символов";
                        }
                        return null;
                      },
                      onChanged: (value) => title = value,
                    ),
                    TextFormField(
                      initialValue: comment,
                      decoration: InputDecoration(labelText: "Комментарий"),
                      maxLength: 512,
                      onChanged: (value) => comment = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: TaskConstants.categories.contains(category)
                          ? category
                          : "Другое",
                      items: TaskConstants.categories
                          .sublist(1)
                          .toSet()
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => category = value!),
                      decoration: InputDecoration(labelText: "Категория"),
                    ),
                    DropdownButtonFormField<String>(
                      value: priority,
                      items: ["high", "medium", "low"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_getPriorityText(value)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => priority = value!),
                      decoration: InputDecoration(labelText: "Приоритет"),
                    ),
                    Slider(
                      value: emotionalLoad.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: emotionalLoad.toString(),
                      onChanged: (value) =>
                          setState(() => emotionalLoad = value.toInt()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDateTimePicker(context, deadline,
                            (DateTime newDate) {
                          setState(() {
                            deadline = newDate;
                          });
                        });
                      },
                      child: Text("Выбрать дату и время"),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  updateTask(task['id'], title, comment, category, priority,
                      emotionalLoad, deadline, context);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  static void updateTask(
    String taskId,
    String title,
    String comment,
    String category,
    String priority,
    int emotionalLoad,
    DateTime deadline,
    BuildContext context,
  ) async {
    try {
      await TaskRepository.updateTask(
        taskId: taskId,
        title: title,
        comment: comment,
        category: category,
        priority: priority,
        emotionalLoad: emotionalLoad,
        deadline: deadline,
      );
    } catch (e) {
      NotificationService.showErrorSnackbar(
          context, "Ошибка обновления: ${e.toString()}");
    }
  }

  static void completeTask(String taskId, BuildContext context) async {
    try {
      await TaskRepository.completeTask(taskId);
      NotificationService.showSuccessSnackbar(context, "Задача выполнена!");
    } catch (e) {
      NotificationService.showErrorSnackbar(
          context, "Ошибка завершения: ${e.toString()}");
    }
  }

  static Future<void> addTask({
    required BuildContext context,
    required String title,
    required String comment,
    required String category,
    required String priority,
    required int emotionalLoad,
    required DateTime deadline,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      await TaskRepository.addTask(
        title: title,
        comment: comment,
        category: category,
        priority: priority,
        emotionalLoad: emotionalLoad,
        deadline: deadline.toUtc(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Задача успешно создана')),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  static Future<void> deleteTask(BuildContext context, String taskId) async {
    try {
      await TaskRepository.deleteTask(taskId);
    } catch (e) {
      NotificationService.showErrorSnackbar(
          context, "Ошибка удаления: ${e.toString()}");
    }
  }

  static void showDateTimePicker(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateTimeSelected) {
    DateTime now = DateTime.now();
    DateTime minDateTime =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    DateTime selectedDateTime =
        initialDate.isBefore(minDateTime) ? minDateTime : initialDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 350,
          padding: EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: selectedDateTime,
                  minimumDate: minDateTime,
                  maximumDate: DateTime(2100),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDateTime = newDateTime;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    onDateTimeSelected(selectedDateTime);
                    Navigator.pop(context);
                  },
                  child: Text("Готово"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return "Высокий";
      case 'medium':
        return "Средний";
      case 'low':
        return "Низкий";
      default:
        return "Неизвестно";
    }
  }
}
