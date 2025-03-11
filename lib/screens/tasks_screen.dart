import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/widgets/task_card.dart';

import '../widgets/app_dropdown.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String selectedSortOption = "Дедлайн";
  final User? user = FirebaseAuth.instance.currentUser;
  final List<String> taskCategories = [
    "Работа",
    "Учёба",
    "Финансы",
    "Здоровье и спорт",
    "Развитие и хобби",
    "Личное",
    "Домашние дела",
    "Путешествия и досуг"
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // ✅ Две вкладки: "Активные" и "Выполненные"
      child: Scaffold(
        appBar: AppBar(
          title: Text("Задачи"),
          bottom: TabBar(
            labelColor: Colors.black, // Цвет активной вкладки
            unselectedLabelColor: Colors.black, // Цвет неактивной вкладки
            indicatorColor: Colors.black, // Цвет подчеркивания вкладки
            tabs: [
              Tab(text: "Активные"),
              Tab(text: "Выполненные"),
            ],
          ),
          actions: [
            AppDropdown(
              selectedOption: selectedSortOption,
              options: ["Дедлайн", "Приоритет", "Эмоциональная нагрузка"],
              onOptionSelected: (value) {
                setState(() {
                  selectedSortOption = value;
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTaskList("active"),
            _buildTaskList("completed"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  String _getPriorityText(String priority) {
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

  void _showAddTaskDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = "";
    String comment = "";
    String category = "Работа";
    String priority = "medium";
    int emotionalLoad = 3;
    DateTime deadline = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Добавить задачу"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
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
                      decoration: InputDecoration(
                          labelText: "Комментарий (дополнительно)"),
                      maxLength: 512,
                      onChanged: (value) => comment = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: taskCategories.map((String value) {
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
                        _showDateTimePicker(context, deadline,
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
                  _addTask(title, comment, category, priority, emotionalLoad,
                      deadline);
                  Navigator.pop(context);
                }
              },
              child: Text("Создать задачу"),
            ),
          ],
        );
      },
    );
  }

  void _addTask(String title, String comment, String category, String priority,
      int emotionalLoad, DateTime deadline) {
    if (title.isEmpty) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
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
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task) {
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
                      decoration: InputDecoration(
                          labelText: "Комментарий (необязательно)"),
                      maxLength: 512,
                      onChanged: (value) => comment = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: taskCategories.map((String value) {
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
                        _showDateTimePicker(context, deadline,
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
                  _updateTask(task['id'], title, comment, category, priority,
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

  void _updateTask(
      String taskId,
      String title,
      String comment,
      String category,
      String priority,
      int emotionalLoad,
      DateTime deadline,
      BuildContext context) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
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

  void _completeTask(String taskId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': 'completed',
    }).then((_) {
      log("✅ Задача выполнена: $taskId");
    }).catchError((error) {
      log("❌ Ошибка выполнения задачи: $error");
    });
  }

  Future<bool?> _showDeleteConfirmation(
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
              onPressed: () => Navigator.pop(context, false), // ❌ Отмена
              child: Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteTask(taskId);
                Navigator.pop(context, true); // ✅ Подтверждение
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Удалить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(String taskId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .delete()
        .then((_) {
      log("✅ Задача удалена: $taskId");
    }).catchError((error) {
      log("❌ Ошибка удаления: $error");
    });
  }

  void _showDateTimePicker(BuildContext context, DateTime initialDate,
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

  Widget _buildTaskList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('tasks')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Отсутствуют задачи"));
        }

        List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        tasks.sort((a, b) {
          if (selectedSortOption == "Дедлайн") {
            return (a['deadline'] as Timestamp)
                .compareTo(b['deadline'] as Timestamp);
          } else if (selectedSortOption == "Приоритет") {
            Map<String, int> priorityOrder = {"high": 3, "medium": 2, "low": 1};
            return priorityOrder[a['priority']]!
                .compareTo(priorityOrder[b['priority']]!);
          } else if (selectedSortOption == "Эмоциональная нагрузка") {
            return a['emotionalLoad'].compareTo(b['emotionalLoad']);
          }
          return 0;
        });

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: tasks.length + 1,
          itemBuilder: (context, index) {
            if (index == tasks.length) {
              return SizedBox(height: 100);
            }
            final task = tasks[index];

            return Dismissible(
                key: Key(task['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmation(context, task['id']);
                },
                child: TaskCard(
                    task: task,
                    onEdit: () => _showEditTaskDialog(context, task),
                    onComplete: () => _completeTask(task['id'])));
          },
        );
      },
    );
  }
}
