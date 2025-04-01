import 'package:flutter/material.dart';
import 'package:flutter_appp/constants/task_constants.dart';
import 'package:flutter_appp/services/task_actions.dart';
import 'package:flutter_appp/services/task_analyzer.dart';

class AddTaskDialog extends StatefulWidget {
  final Function onTaskAdded;

  const AddTaskDialog({required this.onTaskAdded});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late String title = "";
  late String comment = "";
  late String category = "Работа";
  late String priority = "medium";
  late int emotionalLoad = 3;
  late DateTime deadline = DateTime.now();

  @override
  Widget build(BuildContext context) {
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
                  validator: (value) => _validateTitle(value),
                  onChanged: (value) => title = value,
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: "Комментарий (дополнительно)"),
                  maxLength: 512,
                  onChanged: (value) => comment = value,
                ),
                _buildCategorySelector(setState),
                _buildPrioritySelector(setState),
                _buildEmotionalLoadSlider(setState),
                _buildDateTimePicker(setState),
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
          onPressed: () => _submitForm(context),
          child: Text("Создать задачу"),
        ),
      ],
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Название обязательно";
    } else if (value.length > 50) {
      return "Максимум 50 символов";
    }
    return null;
  }

  Widget _buildCategorySelector(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: TaskConstants.categories.contains(category)
              ? category
              : "Другое",
          items: TaskConstants.categories.sublist(1).toSet().map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => setState(() => category = value!),
          decoration: InputDecoration(labelText: "Категория"),
        ),
        ElevatedButton(
          onPressed: () => _analyzeCategory(setState),
          child: Text("Определить категорию задачи"),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(StateSetter setState) {
    return DropdownButtonFormField<String>(
      value: priority,
      items: ["high", "medium", "low"].map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(TaskConstants.getPriorityText(value)),
        );
      }).toList(),
      onChanged: (value) => setState(() => priority = value!),
      decoration: InputDecoration(labelText: "Приоритет"),
    );
  }

  Widget _buildEmotionalLoadSlider(StateSetter setState) {
    return Column(
      children: [
        Slider(
          value: emotionalLoad.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: emotionalLoad.toString(),
          onChanged: (value) => setState(() => emotionalLoad = value.toInt()),
        ),
        ElevatedButton(
          onPressed: () => _analyzeEmotionalLoad(setState),
          child: Text("Определить эмоциональную нагрузку"),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(StateSetter setState) {
    return ElevatedButton(
      onPressed: () => TaskActions.showDateTimePicker(
        context,
        deadline,
            (newDate) => setState(() => deadline = newDate),
      ),
      child: Text("Выбрать дату и время"),
    );
  }

  void _submitForm(BuildContext context) {
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
      widget.onTaskAdded();
      Navigator.pop(context);
    }
  }

  void _analyzeCategory(StateSetter setState) {
    TaskAnalyzer.analyzeCategory(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (newCategory) {
        setState(() => category = newCategory);
        _showSuccessSnackbar('Категория определена: $category', Colors.green);
      },
      onError: _showErrorSnackbar,
    );
  }

  void _analyzeEmotionalLoad(StateSetter setState) {
    TaskAnalyzer.analyzeEmotionalLoad(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (newLoad) {
        setState(() => emotionalLoad = newLoad);
        _showSuccessSnackbar(
            'Нагрузка определена: уровень $emotionalLoad', Colors.blue);
      },
      onError: _showErrorSnackbar,
    );
  }

  void _showSuccessSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color.withOpacity(0.2),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
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
  }
}