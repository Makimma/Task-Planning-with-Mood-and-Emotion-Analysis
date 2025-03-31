import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/constants/task_constants.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/services/task_repository.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import '../services/task_analyzer.dart';
import '../services/task_filter.dart';
import '../widgets/app_dropdown.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];

  Set<String> selectedPriorities = {};
  double minLoad = 1, maxLoad = 5;

  String selectedCategory = "Все категории";
  bool filterByDeadline = false;
  bool filterByPriority = false;
  bool filterByEmotionalLoad = false;

  String selectedSortOption = "Дедлайн";

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
              onPressed: () => _showFilterDialog(context),
            ),
          ],
          title: Row(
            children: [
              SizedBox(width: 16),
              AppDropdown(
                selectedOption: selectedSortOption,
                options: ["Дедлайн", "Приоритет", "Эмоциональная нагрузка"],
                maxWidth: 140,
                onOptionSelected: (value) =>
                    setState(() => selectedSortOption = value),
              ),
              SizedBox(width: 10),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicatorColor: Colors.blue,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Активные'),
                  Tab(text: 'Выполненные'),
                ],
              ),
            ),
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
    User? user = TaskActions.user;
    if (user == null) return;

    QuerySnapshot snapshot = TaskRepository.getTasksByStatus(status) as QuerySnapshot<Object?>;

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
      filteredTasks = TaskFilter.applyFilters(
        tasks: allTasks,
        selectedCategory: selectedCategory,
        selectedPriorities: selectedPriorities,
        minLoad: minLoad,
        maxLoad: maxLoad,
      );
    });
  }

  void _showFilterDialog(BuildContext context) {
    Set<String> tempSelectedPriorities = Set.from(selectedPriorities);
    double tempMinLoad = minLoad, tempMaxLoad = maxLoad;

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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: TaskConstants.categories.map((String value) {
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

                  // Фильтр по приоритету
                  Text("Приоритет:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    children: ["low", "medium", "high"].map((priority) {
                      return FilterChip(
                        label: Text(TaskConstants.getPriorityText(priority)),
                        selected: tempSelectedPriorities.contains(priority),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tempSelectedPriorities.add(priority);
                            } else {
                              tempSelectedPriorities.remove(priority);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),

                  // Фильтр по эмоциональной нагрузке
                  Text("Эмоциональная нагрузка:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(tempMinLoad, tempMaxLoad),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    labels: RangeLabels(
                        tempMinLoad.toString(), tempMaxLoad.toString()),
                    onChanged: (values) {
                      setState(() {
                        tempMinLoad = values.start;
                        tempMaxLoad = values.end;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Отмена"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedPriorities = tempSelectedPriorities;
                      minLoad = tempMinLoad;
                      maxLoad = tempMaxLoad;
                    });
                    _applyFilters();
                    Navigator.pop(context);
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

                    // Выпадающий список категории
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: TaskConstants.categories.contains(category)
                              ? category
                              : "Другое",
                          items: TaskConstants.categories
                              .sublist(1)
                              .toSet()
                              .map((String value) {
                            // ✅ Убираем дубликаты
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => category = value!),
                          decoration: InputDecoration(labelText: "Категория"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            TaskAnalyzer.analyzeCategory(
                                title: title,
                                comment: comment,
                                context: context,
                                onSuccess: (newCategory) {
                                  setState(() {
                                    category = newCategory;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.green),
                                            SizedBox(width: 8),
                                            Text(
                                              'Категория определена: $category',
                                              style: TextStyle(color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green[100],
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  });
                                },
                                onError: (message) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.error, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(message),
                                        ],
                                      ),
                                      backgroundColor: Colors.red[100],
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                });
                          },
                          child: Text("Определить категорию задачи"),
                        ),
                      ],
                    ),

                    DropdownButtonFormField<String>(
                      value: priority,
                      items: ["high", "medium", "low"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(TaskConstants.getPriorityText(value)),
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
                        TaskAnalyzer.analyzeEmotionalLoad(
                            title: title,
                            comment: comment,
                            context: context,
                            onSuccess: (newLoad) {
                              setState(() {
                                emotionalLoad = newLoad;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.emoji_emotions,
                                            color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Нагрузка определена: уровень $emotionalLoad',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.blue[100],
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              });
                            },
                            onError: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(message),
                                    ],
                                  ),
                                  backgroundColor: Colors.red[100],
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            });
                      },
                      child: Text("Определить эмоциональную нагрузку"),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        TaskActions.showDateTimePicker(context, deadline,
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
                  TaskActions.addTask(
                    context: context,
                    title: title,
                    comment: comment,
                    category: category,
                    priority: priority,
                    emotionalLoad: emotionalLoad,
                    deadline: deadline,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text("Создать задачу"),
            ),
          ],
        );
      },
    ).then((_) => setState(() => _fetchTasks("active")));
  }

  Widget _buildTaskList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: TaskRepository.getTasksStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Нет задач"));
        }

        List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...?doc.data() as Map<String, dynamic>?,
          };
        }).toList();

        // Применяем фильтры
        List<Map<String, dynamic>> filteredTasks = TaskFilter.applyFilters(
          tasks: tasks,
          selectedCategory: selectedCategory,
          selectedPriorities: selectedPriorities,
          minLoad: minLoad,
          maxLoad: maxLoad,
        );

        // Сортируем задачи
        TaskFilter.sortTasks(
          tasks: filteredTasks,
          selectedSortOption: selectedSortOption,
        );

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
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
                  return await TaskActions.showDeleteConfirmation(
                      context, task['id']);
                },
                child: TaskCard(
                  task: task,
                  onEdit: () => TaskActions.showEditTaskDialog(context, task),
                  onComplete: () =>
                      TaskActions.completeTask(task['id'], context),
                ));
          },
        );
      },
    );
  }
}
