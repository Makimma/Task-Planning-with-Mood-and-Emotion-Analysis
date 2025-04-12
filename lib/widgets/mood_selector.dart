import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final Function(String) onMoodSelected;

  MoodSelector({required this.selectedMood, required this.onMoodSelected, super.key});

  final List<Map<String, dynamic>> moodOptions = [
    {"widget": MoodWidget(icon: Icons.sentiment_very_satisfied, color: Colors.amber), "type": "Радость"},
    {"widget": MoodWidget(icon: Icons.sentiment_dissatisfied, color: Colors.blue), "type": "Грусть"},
    {"widget": MoodWidget(icon: Icons.sentiment_satisfied, color: Colors.green), "type": "Спокойствие"},
    {"widget": MoodWidget(icon: Icons.sentiment_very_dissatisfied, color: Colors.red), "type": "Усталость"},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moodOptions.map((mood) {
        bool isSelected = selectedMood == mood["type"];

        return Expanded(
          child: GestureDetector(
            onTap: () => onMoodSelected(mood["type"]!),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                    borderRadius: BorderRadius.circular(50), // Делаем круглым
                  ),
                  child: mood["widget"], // Используем кастомный виджет
                ),
                SizedBox(height: 5),
                Text(
                  mood["type"]!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// **Виджет настроения с цветным фоном**
class MoodWidget extends StatelessWidget {
  final IconData icon;
  final Color color;

  MoodWidget({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, // Размер фона
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Круглая форма
        color: color.withOpacity(0.3), // Полупрозрачный цвет
      ),
      child: Icon(
        icon,
        size: 40,
        color: color, // Основной цвет
      ),
    );
  }
}
