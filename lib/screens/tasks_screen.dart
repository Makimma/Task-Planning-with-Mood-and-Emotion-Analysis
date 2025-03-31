import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import '../services/category_service.dart';
import '../services/nlp_service.dart';
import '../services/translation_service.dart';
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
    "Путешествия и досуг",
    "Другое"
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

  void _analyzeTaskCategory(
      String title, String comment, Function(String) updateCategory) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Нет интернет-соединения"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      String formattedTitle = title.trim().endsWith('.') ? title.trim() : "${title.trim()}.";
      String fullText = "$formattedTitle $comment";

      // Проверяем, достаточно ли слов для анализа
      int wordCount = fullText.split(RegExp(r'\s+')).length;
      if (wordCount < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Добавьте больше деталей, минимум 20 слов")),
        );
        return;
      }

      // Переводим текст перед анализом
      String? translatedText =
          await TranslationService.translateText(fullText, "en");
      if (translatedText == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка перевода текста")),
        );
        return;
      }

      // Анализируем категорию
      String? category = await CategoryService.classifyText(translatedText);

      if (category != null) {
        category = taskCategories.contains(category) ? category : "Другое";
      } else {
        category = "Другое";
      }

      updateCategory(category);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Категория определена: $category",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green[100],
        ),
      );
    } on SocketException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📡 Ошибка подключения к серверу"),
          duration: Duration(seconds: 3),
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Превышено время ожидания"),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Ошибка: ${e.toString().split(':').first}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  int _convertSentimentToLoad(double score, double magnitude) {
    if (score >= 0.5 && magnitude < 1.5) return 1;
    if (score >= 0.2 && magnitude < 2.0) return 2;
    if (-0.2 <= score && score < 0.2) return 3;
    if (-0.5 <= score && score < -0.2 && magnitude >= 1.0) return 4;
    return 5;
  }

  void _analyzeTaskEmotionalLoad(
      String title, String comment, Function(int) updateLoad) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Нет интернет-соединения"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      String formattedTitle = title.trim().endsWith('.') ? title.trim() : "${title.trim()}.";
      String fullText = "$formattedTitle $comment";

      // Анализируем тональность текста
      Map<String, double>? sentiment =
          await NaturalLanguageService.analyzeSentiment(fullText);
      if (sentiment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка анализа эмоциональной нагрузки")),
        );
        return;
      }

      double score = sentiment["score"]!;
      double magnitude = sentiment["magnitude"]!;
      int emotionalLoad = _convertSentimentToLoad(score, magnitude);

      // Обновляем UI слайдера в модальном окне
      updateLoad(emotionalLoad);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.emoji_emotions, color: Colors.black),
              SizedBox(width: 8),
              Text(
                "Нагрузка определена: уровень $emotionalLoad",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue[100],
        ),
      );
    } on SocketException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📡 Ошибка подключения к серверу"),
          duration: Duration(seconds: 3),
        ),
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Превышено время ожидания"),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Ошибка: ${e.toString().split(':').first}"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
      if (selectedPriorities.isEmpty &&
          selectedCategory == "Все категории" &&
          minLoad == 1 &&
          maxLoad == 5) {
        filteredTasks = List.from(allTasks);
        return;
      }

      filteredTasks = allTasks.where((task) {
        bool matches = true;

        if (selectedCategory != "Все категории") {
          matches &= task['category'] == selectedCategory;
        }
        if (selectedPriorities.isNotEmpty) {
          matches &= selectedPriorities.contains(task['priority']);
        }
        if (task['emotionalLoad'] != null) {
          int load = task['emotionalLoad'];
          matches &= load >= minLoad && load <= maxLoad;
        }

        return matches;
      }).toList();
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
                    items: [
                      "Все категории",
                      "Работа",
                      "Учёба",
                      "Финансы",
                      "Здоровье и спорт",
                      "Личное"
                    ].map((String value) {
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
                        label: Text(_getPriorityText(priority)),
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

                    // Выпадающий список категории
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: taskCategories.contains(category)
                              ? category
                              : "Другое", // ✅ Гарантированно в списке
                          items: taskCategories.toSet().map((String value) {
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
                            _analyzeTaskCategory(title, comment, (newCategory) {
                              setState(() {
                                category = newCategory;
                              });
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
                        _analyzeTaskEmotionalLoad(title, comment, (newLoad) {
                          setState(() {
                            emotionalLoad = newLoad;
                          });
                        });
                      },
                      child: Text("Определить эмоциональную нагрузку"),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        TaskActions.showDateTimePicker(context, deadline, (DateTime newDate) {
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
    ).then((_) => setState(() => _fetchTasks("active")));
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
        List<Map<String, dynamic>> filteredTasks = tasks.where((task) {
          bool matches = true;

          if (selectedCategory != "Все категории") {
            matches &= task['category'] == selectedCategory;
          }

          if (selectedPriorities.isNotEmpty) {
            matches &= selectedPriorities.contains(task['priority']);
          }

          if (task['emotionalLoad'] != null) {
            int load = task['emotionalLoad'];
            matches &= load >= minLoad && load <= maxLoad;
          }

          return matches;
        }).toList();

        // Сортируем задачи
        filteredTasks.sort((a, b) {
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
                  onComplete: () => TaskActions.completeTask(task['id']),
                ));
          },
        );
      },
    );
  }
}
