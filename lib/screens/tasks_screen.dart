import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import '../widgets/app_dropdown.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> allTasks = [];  // 🔹 Все задачи
  List<Map<String, dynamic>> filteredTasks = []; // 🔹 Отфильтрованные задачи

  String selectedCategory = "Все категории";
  bool filterByDeadline = false;
  bool filterByPriority = false;
  bool filterByEmotionalLoad = false;

  String selectedSortOption = "Дедлайн";
  final User? user = FirebaseAuth.instance.currentUser;
  final List<String> taskCategories = [
    "Все категории",
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
  void initState() {
    super.initState();
    _fetchTasks("active");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
          ],
          title: Row(
            children: [
              SizedBox(width: 16), // ✅ Отступ от края экрана
              AppDropdown(
                selectedOption: selectedSortOption,
                options: ["Дедлайн", "Приоритет", "Эмоциональная нагрузка"],
                maxWidth: 140, // ✅ Ограничиваем ширину
                onOptionSelected: (value) {
                  setState(() {
                    selectedSortOption = value;
                  });
                },
              ),
              SizedBox(width: 10), // ✅ Отступ перед вторым выпадающим списком
              // Flexible(
              //   child: DropdownButton<String>(
              //     value: taskCategories.contains(selectedCategory)
              //         ? selectedCategory
              //         : "Все категории",
              //     items: taskCategories.toSet().map((String value) {
              //       return DropdownMenuItem<String>(
              //         value: value,
              //         child: Text(value,
              //             overflow: TextOverflow
              //                 .ellipsis),
              //       );
              //     }).toList(),
              //     onChanged: (value) {
              //       setState(() {
              //         selectedCategory = value!;
              //       });
              //     },
              //   ),
              // ),
            ],
          ),
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

  void _fetchTasks(String status) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('status', isEqualTo: status)
        .get();

    setState(() {
      allTasks = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      if (!filterByDeadline && !filterByPriority && !filterByEmotionalLoad && selectedCategory == "Все категории") {
        filteredTasks = List.from(allTasks);
        return;
      }

      filteredTasks = allTasks.where((task) {
        bool matches = true;

        if (selectedCategory != "Все категории") {
          matches &= task['category'] == selectedCategory;
        }
        if (filterByDeadline) {
          matches &= task['deadline'] != null;
        }
        if (filterByPriority) {
          matches &= task['priority'] == "high";
        }
        if (filterByEmotionalLoad) {
          matches &= task['emotionalLoad'] > 3;
        }
        return matches;
      }).toList();
    });
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Фильтр задач"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Фильтр по категории
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: ["Все категории", "Работа", "Учёба", "Финансы", "Здоровье и спорт", "Личное"]
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Категория"),
                  ),
                  SizedBox(height: 10),

                  // Фильтр по дедлайну
                  CheckboxListTile(
                    title: Text("Фильтр по дедлайну"),
                    value: filterByDeadline,
                    onChanged: (value) {
                      setState(() {
                        filterByDeadline = value!;
                      });
                    },
                  ),

                  // Фильтр по приоритету
                  CheckboxListTile(
                    title: Text("Фильтр по приоритету"),
                    value: filterByPriority,
                    onChanged: (value) {
                      setState(() {
                        filterByPriority = value!;
                      });
                    },
                  ),

                  // Фильтр по эмоциональной нагрузке
                  CheckboxListTile(
                    title: Text("Фильтр по нагрузке"),
                    value: filterByEmotionalLoad,
                    onChanged: (value) {
                      setState(() {
                        filterByEmotionalLoad = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Закрываем диалог без применения
                  },
                  child: Text("Отмена"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _applyFilters(); // Применяем фильтрацию
                    Navigator.pop(context); // Закрываем диалог
                  },
                  child: Text("Применить"),
                ),
              ],
            );
          },
        );
      },
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
        if (filteredTasks.isEmpty && allTasks.isNotEmpty) {
          return Center(child: Text("Нет задач, соответствующих фильтру"));
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
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            if (index == filteredTasks.length) {
              return SizedBox(height: 100);
            }
            final task = filteredTasks[index];

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
                  return await TaskActions.showDeleteConfirmation(context, task['id']);
                },
                child: TaskCard(
                  task: task,
                  onEdit: () => TaskActions.showEditTaskDialog(context, task),
                  onComplete: () => TaskActions.completeTask(task['id']),
                )
            );
          },
        );
      },
    );
  }
}
