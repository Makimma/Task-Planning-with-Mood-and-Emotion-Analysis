import 'package:flutter/material.dart';
import 'package:flutter_appp/constants/task_constants.dart';
import 'package:flutter_appp/features/tasks/services/task_actions.dart';
import 'package:flutter_appp/features/tasks/services/task_analyzer.dart';
import 'package:flutter/services.dart';

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
  String? categorySuccess;
  String? emotionalLoadSuccess;
  
  // Add FocusNodes
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_onTitleFocusChange);
    _commentFocusNode.addListener(_onCommentFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && title.isNotEmpty) {
      _analyzeParameters(setState);
    }
  }

  void _onCommentFocusChange() {
    if (!_commentFocusNode.hasFocus && (title.isNotEmpty || comment.isNotEmpty)) {
      _analyzeParameters(setState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.light 
              ? Colors.grey[300]!
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Новая задача",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Form(
                key: _formKey,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          label: "Название",
                          onChanged: (value) => title = value,
                          validator: _validateTitle,
                          maxLength: 50,
                          onSubmitted: (_) => _analyzeParameters(setState),
                            focusNode: _titleFocusNode,
                        ),
                        SizedBox(height: 12),
                        _buildTextField(
                          label: "Комментарий",
                          onChanged: (value) => comment = value,
                          maxLength: 512,
                          maxLines: 2,
                          onSubmitted: (_) => _analyzeParameters(setState),
                            focusNode: _commentFocusNode,
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle("Категория"),
                        SizedBox(height: 4),
                        _buildCategorySelector(setState),
                        if (categoryError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              categoryError!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        if (categorySuccess != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              categorySuccess!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 12),
                        _buildSectionTitle("Эмоциональная нагрузка"),
                        SizedBox(height: 4),
                        _buildEmotionalLoadSlider(setState),
                        if (emotionalLoadError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              emotionalLoadError!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        if (emotionalLoadSuccess != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              emotionalLoadSuccess!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 40),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            _analyzeCategory(setState);
                            _analyzeEmotionalLoad(setState);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Обновить параметры"),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildSectionTitle("Приоритет"),
                        SizedBox(height: 4),
                        _buildPrioritySelector(setState),
                        SizedBox(height: 12),
                        _buildDateTimeSection(setState),
                        SizedBox(height: 12),
                        _buildReminderSection(setState),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Отмена",
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _submitForm(context),
                              child: Text("Создать"),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    int? maxLength,
    int? maxLines,
    Function(String)? onSubmitted,
    required FocusNode focusNode,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Theme.of(context).dividerColor.withOpacity(0.3)
                : Colors.grey[350]!,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Theme.of(context).dividerColor.withOpacity(0.3)
                : Colors.grey[350]!,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(fontSize: 14),
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }

  Widget _buildCategorySelector(StateSetter setState) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: category,
          isExpanded: true,
          padding: EdgeInsets.symmetric(horizontal: 16),
          items: TaskConstants.categories.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                category = newValue;
                categorySuccess = null;
                categoryError = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(StateSetter setState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8.0,
      children: ["low", "medium", "high"].map((value) {
        final isSelected = priority == value;
        return GestureDetector(
          onTap: () => setState(() => priority = value),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : isDarkMode 
                        ? Theme.of(context).dividerColor.withOpacity(0.3)
                        : Colors.grey[350]!,
                width: 1.2,
              ),
            ),
            child: Text(
              TaskConstants.getPriorityText(value),
              style: TextStyle(
                color: isSelected 
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionalLoadSlider(StateSetter setState) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: emotionalLoad.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            onChanged: (value) {
              setState(() {
                emotionalLoad = value.toInt();
                emotionalLoadSuccess = null;
                emotionalLoadError = null;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "1",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            Text(
              "5",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(StateSetter setState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Дедлайн"),
        SizedBox(height: 8),
        InkWell(
          onTap: () => TaskActions.showDateTimePicker(
            context,
            deadline,
            (newDate) => setState(() => deadline = newDate),
          ),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode 
                    ? Theme.of(context).dividerColor.withOpacity(0.3)
                    : Colors.grey[350]!,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 12),
                Text(
                  "${deadline.day}.${deadline.month}.${deadline.year} ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection(StateSetter setState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final options = {
      0: "Не уведомлять",
      15: "15 минут",
      60: "1 час",
      180: "3 часа",
      1440: "1 день"
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Напоминание за"),
        SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode 
                  ? Theme.of(context).dividerColor.withOpacity(0.3)
                  : Colors.grey[350]!,
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: reminderOffsetMinutes,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down),
              padding: EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              items: options.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => reminderOffsetMinutes = value!),
            ),
          ),
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
    if (title.isNotEmpty || comment.isNotEmpty) {
      _analyzeCategory(setState);
      _analyzeEmotionalLoad(setState);
    }
  }

  void _analyzeCategory(StateSetter setState) {
    setState(() {
      categoryError = null;
      categorySuccess = null;
    });

    TaskAnalyzer.analyzeCategory(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (result) {
        setState(() {
          category = result;
          categorySuccess = "Категория определена: $result";
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
    setState(() {
      emotionalLoadError = null;
      emotionalLoadSuccess = null;
    });

    TaskAnalyzer.analyzeEmotionalLoad(
      title: title,
      comment: comment,
      context: context,
      onSuccess: (result) {
        setState(() {
          emotionalLoad = result;
          emotionalLoadSuccess = "Эмоциональная нагрузка определена: $result";
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