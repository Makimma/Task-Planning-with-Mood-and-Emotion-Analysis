import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/task_constants.dart';

class TaskFilter {
  static List<Map<String, dynamic>> applyFilters({
    required List<Map<String, dynamic>> tasks,
    required String selectedCategory,
    required Set<String> selectedPriorities,
    required double minLoad,
    required double maxLoad,
  }) {
    return tasks.where((task) {
      bool matches = true;

      if (selectedCategory != TaskConstants.categories[0]) {
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
  }

  static void sortTasks({
    required List<Map<String, dynamic>> tasks,
    required String selectedSortOption,
  }) {
    tasks.sort((a, b) {
      switch (selectedSortOption) {
        case "Дата создания":
          final dateA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final dateB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return dateB.compareTo(dateA);
        case "Дедлайн":
          return (a['deadline'] as Timestamp)
              .compareTo(b['deadline'] as Timestamp);
        case "Приоритет":
          final priorityOrder = {"high": 3, "medium": 2, "low": 1};
          return priorityOrder[a['priority']]!
              .compareTo(priorityOrder[b['priority']]!);
        case "Эмоциональная нагрузка":
          return a['emotionalLoad'].compareTo(b['emotionalLoad']);
        default:
          return 0;
      }
    });
  }
}
