import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];

  Set<String> selectedPriorities = {};
  double minLoad = 1, maxLoad = 5;

  String selectedCategory = "Все категории";
  bool filterByDeadline = false;
  bool filterByPriority = false;
  bool filterByEmotionalLoad = false;

  String selectedSortOption = "Дата создания";

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
              onPressed: () => showDialog(
                context: context,
                builder: (context) => FilterDialog(
                  selectedCategory: selectedCategory,
                  selectedPriorities: selectedPriorities,
                  minLoad: minLoad,
                  maxLoad: maxLoad,
                  onCategoryChanged: (value) => setState(() => selectedCategory = value),
                  onPriorityChanged: (value) => setState(() => selectedPriorities = value),
                  onLoadChanged: (newMin, newMax) => setState(() {
                    minLoad = newMin;
                    maxLoad = newMax;
                  }),
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
                onOptionSelected: (value) =>
                    setState(() => selectedSortOption = value),
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
              onTaskAdded: () => _fetchTasks("active"),
            ),
          ),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _fetchTasks(String status) async {
    User? user = TaskActions.user;
    if (user == null) return;

    QuerySnapshot snapshot = await TaskRepository.getTasksByStatus(status);

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
          padding: EdgeInsets.only(bottom: 100),
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
                  isCompleted: true,
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
