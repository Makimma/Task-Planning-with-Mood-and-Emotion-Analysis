import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final String selectedMood;
  final Function(String) onMoodSelected;

  MoodSelector(
      {required this.selectedMood, required this.onMoodSelected, super.key});

  final List<Map<String, String>> moodOptions = [
    {"emoji": "😊", "type": "Радость"},
    {"emoji": "😢", "type": "Грусть"},
    {"emoji": "😌", "type": "Спокойствие"},
    {"emoji": "😫", "type": "Усталость"},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moodOptions.map((mood) {
        return Expanded(
          child: GestureDetector(
            onTap: () => onMoodSelected(mood["type"]!),
            child: Column(
              children: [
                Text(mood["emoji"]!, style: TextStyle(fontSize: 30)),
                SizedBox(height: 5),
                Text(mood["type"]!, style: TextStyle(fontSize: 14)),
                if (selectedMood == mood["type"])
                  Icon(Icons.check, color: Colors.green),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
