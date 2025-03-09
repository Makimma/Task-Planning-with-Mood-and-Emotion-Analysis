import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ваши задачи")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('tasks')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Нет активных задач"));
          }

          List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();


          tasks.sort((a, b) {
            Timestamp timestampA = a['deadline'];
            Timestamp timestampB = b['deadline'];
            return timestampA.compareTo(timestampB);
          });

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                child: ListTile(
                  title: Text(task['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Категория: ${task['category']}"),
                      Text("Дедлайн: ${_formatTimestamp(task['deadline'])}"),
                      Text("Приоритет: ${_getPriorityText(task['priority'])}"),
                      Text("Эмоциональная нагрузка: ${task['emotionalLoad']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditTaskDialog(context, task),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}";
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
                      decoration: InputDecoration(labelText: "Комментарий (дополнительно)"),
                      maxLength: 512,
                      onChanged: (value) => comment = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ["Работа", "Учёба", "Финансы", "Здоровье и спорт", "Развитие и хобби", "Личное", "Домашние дела", "Путешествие и досуг"].map((String value) {
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
                      onChanged: (value) => setState(() => emotionalLoad = value.toInt()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              deadline = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text("Выбрать дедлайн"),
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
                  _addTask(title, comment, category, priority, emotionalLoad, deadline);
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

  void _addTask(String title, String comment, String category, String priority, int emotionalLoad, DateTime deadline) {
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
                      decoration: InputDecoration(labelText: "Комментарий (необязательно)"),
                      maxLength: 512,
                      onChanged: (value) => comment = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ["Работа", "Учёба", "Личное", "Дом"].map((String value) {
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
                      onChanged: (value) => setState(() => emotionalLoad = value.toInt()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              deadline = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text("Выбрать дедлайн"),
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
                  _updateTask(task['id'],
                      title,
                      comment,
                      category,
                      priority,
                      emotionalLoad,
                      deadline,
                      context);
                }
              },
              child: Text("Save"),
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
    }).then((_) {
      log("✅ Task updated successfully!");
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }).catchError((error) {
      log("❌ Firestore update error: $error");
    });
  }


}
