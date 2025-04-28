import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appp/features/tasks/services/task_actions.dart';
import 'package:flutter_appp/features/tasks/services/task_repository.dart';
import 'package:flutter_appp/features/tasks/widgets/task_card.dart';
import '../services/task_filter.dart';
import '../widgets/add_task_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../widgets/filter_task_dialog.dart';
import '../../../core/widgets/sort_selector.dart';
import '../../../core/widgets/search_field.dart';
import '../../../features/auth/screens/auth_screen.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  String searchQuery = '';

  // Add state variables for controlling visibility
  bool isSearchVisible = true;
  bool isSortVisible = false;

  Set<String> selectedPriorities = {};
  double minLoad = 1, maxLoad = 5;

  String selectedCategory = "Все категории";
  bool filterByDeadline = false;
  bool filterByPriority = false;
  bool filterByEmotionalLoad = false;

  String selectedSortOption = "Дата создания";
  bool _isInitialized = false;
  StreamSubscription? _activeTasksSubscription;
  StreamSubscription? _completedTasksSubscription;
  StreamSubscription? _authStateSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _activeTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _initializeScreen() {
    // Подписываемся на изменения состояния авторизации
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // Если пользователь не авторизован, перенаправляем на экран авторизации
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (route) => false,
        );
      } else {
        // Если пользователь авторизован, инициализируем задачи
        _initializeTasks();
      }
    });
  }

  void _initializeTasks() {
    try {
      _activeTasksSubscription?.cancel();
      _completedTasksSubscription?.cancel();

      _activeTasksSubscription = TaskRepository.getTasksStream("active").listen(
        (snapshot) {
          if (!mounted) return;
          _updateTasks(snapshot, "active");
        },
        onError: (error) {
          print('Error fetching active tasks: $error');
          if (error.toString().contains('Пользователь не авторизован')) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => AuthScreen()),
              (route) => false,
            );
          }
        },
      );

      _completedTasksSubscription = TaskRepository.getTasksStream("completed").listen(
        (snapshot) {
          if (!mounted) return;
          _updateTasks(snapshot, "completed");
        },
        onError: (error) {
          print('Error fetching completed tasks: $error');
        },
      );
    } catch (e) {
      print('Error initializing tasks: $e');
      if (e.toString().contains('Пользователь не авторизован')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _updateTasks(QuerySnapshot snapshot, String status) {
    List<Map<String, dynamic>> tasks = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();

    if (status == "active") {
      setState(() {
        allTasks = tasks;
        _applyFilters();
        _isInitialized = true;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = TaskFilter.applyFilters(
      tasks: allTasks,
      selectedCategory: selectedCategory,
      selectedPriorities: selectedPriorities,
      minLoad: minLoad,
      maxLoad: maxLoad,
      searchQuery: searchQuery,
    );

    TaskFilter.sortTasks(
      tasks: filtered,
      selectedSortOption: selectedSortOption,
    );

    if (mounted) {
      setState(() {
        filteredTasks = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedCrossFade(
                    duration: Duration(milliseconds: 300),
                    firstChild: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              isSearchVisible = true;
                              isSortVisible = false;
                            });
                          },
                        ),
                      ],
                    ),
                    secondChild: SearchField(
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        _applyFilters();
                      },
                      onClose: () {
                        setState(() {
                          isSearchVisible = false;
                          searchQuery = '';
                        });
                        _applyFilters();
                      },
                    ),
                    crossFadeState: isSearchVisible 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => FilterDialog(
                      selectedCategory: selectedCategory,
                      selectedPriorities: selectedPriorities,
                      minLoad: minLoad,
                      maxLoad: maxLoad,
                      onCategoryChanged: (value) {
                        setState(() => selectedCategory = value);
                        _applyFilters();
                      },
                      onPriorityChanged: (value) {
                        setState(() => selectedPriorities = value);
                        _applyFilters();
                      },
                      onLoadChanged: (newMin, newMax) {
                        setState(() {
                          minLoad = newMin;
                          maxLoad = newMax;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: Duration(milliseconds: 300),
                  firstChild: Tooltip(
                    message: "Сортировка: $selectedSortOption",
                    child: IconButton(
                      icon: Icon(_getSortIcon()),
                      onPressed: () {
                        setState(() {
                          isSortVisible = true;
                          isSearchVisible = false;
                          searchQuery = '';
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  secondChild: SortSelector(
                    selectedOption: selectedSortOption,
                    onOptionSelected: (value) {
                      setState(() => selectedSortOption = value);
                      _applyFilters();
                    },
                    onClose: () {
                      setState(() {
                        isSortVisible = false;
                      });
                    },
                  ),
                  crossFadeState: isSortVisible 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                children: [
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Активные'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Выполненные'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              onTaskAdded: () => _initializeTasks(),
            ),
          ),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskList(String status) {
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    if (status == "active") {
      if (filteredTasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Нет задач",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.only(top: 8, bottom: 80),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return Dismissible(
            key: Key(task['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return await TaskActions.showDeleteConfirmation(context, task['id']);
            },
            child: TaskCard(
              task: task,
              isCompleted: false,
              onEdit: () => TaskActions.showEditTaskDialog(context, task),
              onComplete: () => TaskActions.completeTask(task['id'], context),
            ),
          );
        },
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: TaskRepository.getTasksStream("completed"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Нет выполненных задач",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          // Apply filters to completed tasks
          List<Map<String, dynamic>> filteredCompletedTasks = TaskFilter.applyFilters(
            tasks: tasks,
            selectedCategory: selectedCategory,
            selectedPriorities: selectedPriorities,
            minLoad: minLoad,
            maxLoad: maxLoad,
            searchQuery: searchQuery,
          );

          TaskFilter.sortTasks(
            tasks: filteredCompletedTasks,
            selectedSortOption: selectedSortOption,
          );

          if (filteredCompletedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Нет выполненных задач",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(top: 8, bottom: 80),
            itemCount: filteredCompletedTasks.length,
            itemBuilder: (context, index) {
              final task = filteredCompletedTasks[index];
              return TaskCard(
                task: task,
                isCompleted: true,
                onEdit: null,
                onComplete: () => TaskActions.completeTask(task['id'], context),
              );
            },
          );
        },
      );
    }
  }

  IconData _getSortIcon() {
    switch (selectedSortOption) {
      case "Дата создания":
        return Icons.access_time_rounded;
      case "Дедлайн":
        return Icons.calendar_today_rounded;
      case "Приоритет":
        return Icons.priority_high_rounded;
      case "Эмоц. нагрузка":
        return Icons.psychology_rounded;
      default:
        return Icons.sort;
    }
  }
}
