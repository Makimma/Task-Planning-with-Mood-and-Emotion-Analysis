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
  int reminderOffsetMinutes = 0;
  String? categoryError;
  String? emotionalLoadError;

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
                  onFieldSubmitted: (_) => _analyzeParameters(setState),
                  onEditingComplete: () => _analyzeParameters(setState),
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: "Комментарий (дополнительно)"),
                  maxLength: 512,
                  onChanged: (value) => comment = value,
                  onFieldSubmitted: (_) => _analyzeParameters(setState),
                  onEditingComplete: () => _analyzeParameters(setState),
                ),
                _buildCategorySelector(setState),
                _buildPrioritySelector(setState),
                _buildEmotionalLoadSlider(setState),
                _buildAnalysisButton(setState),
                _buildDateTimePicker(setState),
                _buildReminderDropdown(setState),
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
          onChanged: (value) => setState(() {
            category = value!;
            categoryError = null;
          }),
          decoration: InputDecoration(labelText: "Категория"),
        ),
        if (categoryError != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              categoryError!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
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
          onChanged: (value) => setState(() {
            emotionalLoad = value.toInt();
            emotionalLoadError = null;
          }),
        ),
        if (emotionalLoadError != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              emotionalLoadError!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalysisButton(StateSetter setState) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          _analyzeCategory(setState);
          _analyzeEmotionalLoad(setState);
        },
        icon: Icon(Icons.auto_awesome),
        label: Text("Обновить параметры"),
      ),
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

  Widget _buildReminderDropdown(StateSetter setState) {
    final options = {
      0: "Не уведомлять",
      15: "15 минут",
      60: "1 час",
      180: "3 часа",
      1440: "1 день"
    };

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: DropdownButtonFormField<int>(
        value: reminderOffsetMinutes,
        onChanged: (value) => setState(() => reminderOffsetMinutes = value!),
        items: options.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        decoration: InputDecoration(labelText: "🔔 Напомнить за"),
      ),
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
        reminderOffsetMinutes: reminderOffsetMinutes,
      );
      widget.onTaskAdded();
      Navigator.pop(context);
    }
  }

  void _analyzeParameters(StateSetter setState) {
    if (title.isNotEmpty) {
      _analyzeCategory(setState);
      _analyzeEmotionalLoad(setState);
    }
  }

  void _analyzeCategory(StateSetter setState) {
    TaskAnalyzer.analyzeCategory(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (newCategory) {
        setState(() {
          category = newCategory;
          categoryError = null;
        });
      },
      onError: (error) {
        setState(() {
          categoryError = error;
        });
      },
    );
  }

  void _analyzeEmotionalLoad(StateSetter setState) {
    TaskAnalyzer.analyzeEmotionalLoad(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (newLoad) {
        setState(() {
          emotionalLoad = newLoad;
          emotionalLoadError = null;
        });
      },
      onError: (error) {
        setState(() {
          emotionalLoadError = error;
        });
      },
    );
  }
}