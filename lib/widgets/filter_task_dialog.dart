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
        return AlertDialog(
          title: Text("Фильтр задач"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempCategory,
                items: TaskConstants.categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => tempCategory = value!),
                decoration: InputDecoration(labelText: "Категория"),
              ),
              SizedBox(height: 10),
              Text("Приоритет:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: ["low", "medium", "high"].map((priority) {
                  return FilterChip(
                    label: Text(TaskConstants.getPriorityText(priority)),
                    selected: tempPriorities.contains(priority),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          tempPriorities.add(priority);
                        } else {
                          tempPriorities.remove(priority);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Text("Эмоциональная нагрузка:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 1,
                max: 5,
                divisions: 4,
                labels: RangeLabels(tempMin.toString(), tempMax.toString()),
                onChanged: (values) {
                  setState(() {
                    tempMin = values.start;
                    tempMax = values.end;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                onCategoryChanged(tempCategory);
                onPriorityChanged(tempPriorities);
                onLoadChanged(tempMin, tempMax);
                Navigator.pop(context);
              },
              child: Text("Применить"),
            ),
          ],
        );
      },
    );
  }
}
