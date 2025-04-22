import 'package:flutter/material.dart';
import 'gradient_mood_icon.dart';

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final Function(String) onMoodSelected;

  const MoodSelector({
    Key? key,
    required this.selectedMood,
    required this.onMoodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> moods = ["Радость", "Грусть", "Спокойствие", "Усталость"];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 4;
        
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: moods.map((mood) {
            final isSelected = selectedMood == mood;

            return SizedBox(
              width: itemWidth,
            child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                  GestureDetector(
                    onTap: () => onMoodSelected(mood),
                    child: GradientMoodIcon(
                      mood: mood,
                      size: 56,
                      isSelected: isSelected,
                    ),
                ),
                  SizedBox(height: 8),
                Text(
                    mood,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                  ),
                ),
              ],
            ),
            );
          }).toList(),
        );
      },
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
