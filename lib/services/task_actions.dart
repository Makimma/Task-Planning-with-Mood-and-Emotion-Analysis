import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskActions {
  static void showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
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
                      value: category,
                      items: ["Работа", "Учёба", "Финансы", "Здоровье", "Личное"]
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
                        _showDateTimePicker(context, deadline, (DateTime newDate) {
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
              },
              child: Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  static void updateTask(String taskId, String title, String comment,
      String category, String priority, int emotionalLoad,
      DateTime deadline, BuildContext context) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
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

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  static void completeTask(String taskId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  static void deleteTask(String taskId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  static void _showDateTimePicker(
      BuildContext context, DateTime initialDate, Function(DateTime) onDateTimeSelected) {
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
