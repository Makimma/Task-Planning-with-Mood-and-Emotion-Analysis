import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;
  final bool isCompleted;

  const TaskCard({
    required this.task,
    this.onEdit,
    this.onComplete,
    required this.isCompleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DateTime deadline = _convertToDateTime(task['deadline']);
    bool isOverdue = !isCompleted && _isOverdue(deadline);
    Color priorityColor = _getPriorityColor(context, task['priority']);
    Color emotionalLoadColor = _getTaskColor(context, task['emotionalLoad']);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: Theme.of(context).brightness == Brightness.light ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? Colors.red.withOpacity(
                  Theme.of(context).brightness == Brightness.light ? 0.5 : 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (!isCompleted) ...[
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.green.withOpacity(0.15)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.check_circle_outline, size: 28),
                        color: Colors.green,
                        onPressed: onComplete,
                        tooltip: 'Отметить как выполненную',
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.category,
                    label: task['category'],
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    icon: Icons.priority_high,
                    label: _getPriorityText(task['priority']),
                    color: priorityColor,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.access_time,
                    label: _formatTimestamp(deadline),
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    icon: Icons.psychology,
                    label: 'Нагрузка: ${task['emotionalLoad']}',
                    color: emotionalLoadColor,
                  ),
                ],
              ),
              if (isOverdue) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Просрочено',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isDarkMode ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Высокий';
      case 'medium':
        return 'Средний';
      case 'low':
        return 'Низкий';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(BuildContext context, String priority) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case 'high':
        return isDarkMode ? Colors.red[400]! : Colors.red[600]!;
      case 'medium':
        return isDarkMode ? Colors.orange[400]! : Colors.orange[600]!;
      case 'low':
        return isDarkMode ? Colors.green[400]! : Colors.green[600]!;
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  DateTime _convertToDateTime(dynamic deadline) {
    if (deadline is Timestamp) {
      return deadline.toDate();
    } else if (deadline is DateTime) {
      return deadline;
    } else {
      throw ArgumentError("Неподдерживаемый формат даты");
    }
  }

  bool _isOverdue(DateTime deadline) {
    DateTime now = DateTime.now();
    return deadline.isBefore(now);
  }

  String _formatTimestamp(DateTime date) {
    final local = date.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return "${local.day}.${local.month}.${local.year} $hours:$minutes";
  }

  Color _getTaskColor(BuildContext context, int emotionalLoad) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (emotionalLoad >= 4) {
      return isDarkMode ? Colors.red[300]! : Colors.red[400]!;
    } else if (emotionalLoad == 3) {
      return isDarkMode ? Colors.yellow[300]! : Colors.orange[400]!;
    } else {
      return isDarkMode ? Colors.green[300]! : Colors.green[400]!;
    }
  }
}
