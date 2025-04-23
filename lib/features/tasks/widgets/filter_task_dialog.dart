import 'package:flutter/material.dart';
import 'package:flutter_appp/constants/task_constants.dart';

class FilterDialog extends StatelessWidget {
  final String selectedCategory;
  final Set<String> selectedPriorities;
  final double minLoad;
  final double maxLoad;
  final Function(String) onCategoryChanged;
  final Function(Set<String>) onPriorityChanged;
  final Function(double, double) onLoadChanged;

  const FilterDialog({
    required this.selectedCategory,
    required this.selectedPriorities,
    required this.minLoad,
    required this.maxLoad,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onLoadChanged,
  });

  @override
  Widget build(BuildContext context) {
    String tempCategory = selectedCategory;
    Set<String> tempPriorities = Set.from(selectedPriorities);
    double tempMin = minLoad;
    double tempMax = maxLoad;

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Фильтры",
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
                SizedBox(height: 20),
                Text(
                  "Категория",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempCategory,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(8),
                      items: TaskConstants.categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => tempCategory = value!),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Приоритет",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: ["low", "medium", "high"].map((priority) {
                    final isSelected = tempPriorities.contains(priority);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            tempPriorities.remove(priority);
                          } else {
                            tempPriorities.add(priority);
                          }
                        });
                      },
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
                                : Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          TaskConstants.getPriorityText(priority),
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
                ),
                SizedBox(height: 20),
                Text(
                  "Эмоциональная нагрузка",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(tempMin, tempMax),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  labels: RangeLabels(
                    tempMin.toInt().toString(),
                    tempMax.toInt().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      tempMin = values.start;
                      tempMax = values.end;
                    });
                  },
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
                SizedBox(height: 24),
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
                      onPressed: () {
                        onCategoryChanged(tempCategory);
                        onPriorityChanged(tempPriorities);
                        onLoadChanged(tempMin, tempMax);
                        Navigator.pop(context);
                      },
                      child: Text("Применить"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
