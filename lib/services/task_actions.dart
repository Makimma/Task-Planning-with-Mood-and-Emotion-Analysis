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
    int reminderOffset = task['reminderOffset'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside input fields
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Редактировать задачу",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: title,
                                decoration: InputDecoration(
                                  labelText: "Название",
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                style: TextStyle(fontSize: 14),
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
                              SizedBox(height: 12),
                    TextFormField(
                      initialValue: comment,
                                decoration: InputDecoration(
                                  labelText: "Комментарий",
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                style: TextStyle(fontSize: 14),
                      maxLength: 512,
                                maxLines: 2,
                      onChanged: (value) => comment = value,
                    ),
                              SizedBox(height: 12),
                              Text(
                                "Категория",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: TaskConstants.categories
                                            .contains(category)
                          ? category
                          : "Другое",
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    borderRadius: BorderRadius.circular(8),
                      items: TaskConstants.categories
                          .sublist(1)
                          .toSet()
                                        .map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(fontSize: 14),
                                        ),
                        );
                      }).toList(),
                                    onChanged: (value) =>
                                        setState(() => category = value!),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Эмоциональная нагрузка",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4),
                              Column(
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 4,
                                      thumbShape: RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                      value: emotionalLoad.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                                      activeColor:
                                          Theme.of(context).colorScheme.primary,
                                      inactiveColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2),
                                      onChanged: (value) => setState(
                                          () => emotionalLoad = value.toInt()),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "1",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.5),
                                          ),
                                        ),
                                        Text(
                                          "5",
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
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Приоритет",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 4),
                              Wrap(
                                spacing: 8.0,
                                children:
                                    ["low", "medium", "high"].map((value) {
                                  final isSelected = priority == value;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => priority = value),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .dividerColor
                                                  .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _getPriorityText(value),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Дедлайн",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () => showDateTimePicker(
                                  context,
                                  deadline,
                                  (newDate) =>
                                      setState(() => deadline = newDate),
                                ),
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "${deadline.day}.${deadline.month}.${deadline.year} ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Напоминание за",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: reminderOffset,
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                    borderRadius: BorderRadius.circular(8),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 0,
                                          child: Text("Не уведомлять")),
                                      DropdownMenuItem(
                                          value: 15, child: Text("15 минут")),
                                      DropdownMenuItem(
                                          value: 60, child: Text("1 час")),
                                      DropdownMenuItem(
                                          value: 180, child: Text("3 часа")),
                                      DropdownMenuItem(
                                          value: 1440, child: Text("1 день")),
                                    ],
                                    onChanged: (value) => setState(
                                        () => reminderOffset = value ?? 0),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "Отмена",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
            ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                                        updateTask(
                                          task['id'],
                                          title,
                                          comment,
                                          category,
                                          priority,
                                          emotionalLoad,
                                          deadline,
                                          reminderOffset,
                                          context,
                                        );
                                        Navigator.pop(context);
                                      }
              },
              child: Text("Сохранить"),
            ),
          ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> updateTask(
    String taskId,
    String title,
    String comment,
    String category,
    String priority,
    int emotionalLoad,
    DateTime deadline,
    int reminderOffset,
    BuildContext context,
  ) async {
    try {
      await NotificationService.cancelReminder(taskId.hashCode);
      if (reminderOffset > 0) {
        await NotificationService.scheduleReminder(
          id: taskId.hashCode,
          title: title,
          reminderTime: deadline.subtract(Duration(minutes: reminderOffset)),
        );
        print('🔔 Создано новое уведомление для задачи: $title');
      } else {
        print('🔕 Уведомления для задачи отключены: $title');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showErrorSnackbar(
          context, "Ошибка обновления уведомления: ${e.toString()}");
      }
      return;
    }

    try {
      await TaskRepository.updateTask(
        taskId: taskId,
        title: title,
        comment: comment,
        category: category,
        priority: priority,
        emotionalLoad: emotionalLoad,
        deadline: deadline,
          reminderOffset: reminderOffset);
    } catch (e) {
      NotificationService.showErrorSnackbar(
          context, "Ошибка обновления: ${e.toString()}");
    }
  }

  static void completeTask(String taskId, BuildContext context) async {
    try {
      await NotificationService.cancelReminder(taskId.hashCode);
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
    required int reminderOffsetMinutes,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      final docRef = await TaskRepository.addTask(
        title: title,
        comment: comment,
        category: category,
        priority: priority,
        emotionalLoad: emotionalLoad,
        deadline: deadline.toUtc(),
        reminderOffsetMinutes: reminderOffsetMinutes,
      );

      if (reminderOffsetMinutes > 0) {
        await NotificationService.scheduleReminder(
          id: docRef.id.hashCode,
          title: title,
          reminderTime:
              deadline.subtract(Duration(minutes: reminderOffsetMinutes)),
        );
      }
      print(
          'Reminder at: ${deadline.subtract(Duration(minutes: reminderOffsetMinutes))}');
      print('Now: ${DateTime.now()}');

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
      await NotificationService.cancelReminder(taskId.hashCode);
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
