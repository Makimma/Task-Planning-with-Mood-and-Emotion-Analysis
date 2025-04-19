import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/services/task_repository.dart';
import 'package:flutter_appp/widgets/task_card.dart';
import '../services/task_filter.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/filter_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  @override
  void dispose() {
    _activeTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    super.dispose();
  }

  void _initializeTasks() {
    _activeTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();

    _activeTasksSubscription = TaskRepository.getTasksStream("active").listen((snapshot) {
      if (!mounted) return;
      _updateTasks(snapshot, "active");
    });

    _completedTasksSubscription = TaskRepository.getTasksStream("completed").listen((snapshot) {
      if (!mounted) return;
      _updateTasks(snapshot, "completed");
    });
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
          actions: [
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
          ],
          title: Row(
            children: [
              SizedBox(width: 16),
              AppDropdown(
                selectedOption: selectedSortOption,
                options: ["Дата создания", "Дедлайн", "Приоритет", "Эмоциональная нагрузка"],
                maxWidth: 140,
                onOptionSelected: (value) {
                  setState(() => selectedSortOption = value);
                  _applyFilters();
                },
              ),
              SizedBox(width: 10),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).textTheme.bodyLarge?.color,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
        return Center(child: Text("Нет задач"));
      }

      return ListView.builder(
        padding: EdgeInsets.only(top: 16, bottom: 80),
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
            return Center(child: Text("Нет выполненных задач"));
          }

          List<Map<String, dynamic>> tasks = snapshot.data!.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          return ListView.builder(
            padding: EdgeInsets.only(top: 16, bottom: 80),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                isCompleted: true,
                onEdit: () => TaskActions.showEditTaskDialog(context, task),
                onComplete: () => TaskActions.completeTask(task['id'], context),
              );
            },
          );
        },
      );
    }
  }
}
