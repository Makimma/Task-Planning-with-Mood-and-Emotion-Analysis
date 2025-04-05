import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onEdit;
  final VoidCallback? onComplete;

  const TaskCard({required this.task, this.onEdit, this.onComplete, super.key});

  @override
  Widget build(BuildContext context) {
    bool isCompleted = task['status'] == "completed";
    DateTime deadline = _convertToDateTime(task['deadline']); // Преобразуем тип

    return Card(
      color: _isOverdue(deadline) ? Colors.red.shade100 : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 80,
            decoration: BoxDecoration(
              color: _getTaskColor(task['emotionalLoad']),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              title: Text(task['title'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Категория: ${task['category']}"),
                  Text("Дедлайн: ${_formatTimestamp(deadline)}"),
                  Text("Приоритет: ${task['priority']}"),
                  Text("Эмоциональная нагрузка: ${task['emotionalLoad']}"),
                ],
              ),
              trailing: isCompleted
                  ? null
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onComplete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    final local = date.toLocal(); // приводим к локальному времени
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return "${local.day}.${local.month}.${local.year} $hours:$minutes";
  }

  Color _getTaskColor(int emotionalLoad) {
    if (emotionalLoad >= 4) {
      return Colors.red.shade300;
    } else if (emotionalLoad == 3) {
      return Colors.yellow.shade300;
    } else {
      return Colors.green.shade300;
    }
  }
}
