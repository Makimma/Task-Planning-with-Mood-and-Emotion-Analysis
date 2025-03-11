import 'package:flutter/material.dart';

class AppDropdown extends StatelessWidget {
  final String selectedOption;
  final Function(String) onOptionSelected;
  final List<String> options;

  const AppDropdown({required this.selectedOption, required this.onOptionSelected, required this.options, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: selectedOption,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onOptionSelected(value);
          }
        },
      ),
    );
  }
}
