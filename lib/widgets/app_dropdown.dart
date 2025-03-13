import 'package:flutter/material.dart';

class AppDropdown extends StatelessWidget {
  final String selectedOption;
  final Function(String) onOptionSelected;
  final List<String> options;
  final double maxWidth;

  const AppDropdown({
    required this.selectedOption,
    required this.onOptionSelected,
    required this.options,
    this.maxWidth = 140,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DropdownButton<String>(
          value: selectedOption,
          isExpanded: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onOptionSelected(value);
            }
          },
        ),
      ),
    );
  }
}
