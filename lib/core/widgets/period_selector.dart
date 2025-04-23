import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      constraints: BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton(context, "Неделя"),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          _buildPeriodButton(context, "Месяц"),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, String period) {
    final isSelected = selectedPeriod == period;
    final textColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPeriodChanged(period),
          borderRadius: BorderRadius.horizontal(
            left: period == "Неделя" ? Radius.circular(8) : Radius.zero,
            right: period == "Месяц" ? Radius.circular(8) : Radius.zero,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: period == "Неделя" ? Radius.circular(8) : Radius.zero,
                right: period == "Месяц" ? Radius.circular(8) : Radius.zero,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    period == "Неделя" 
                        ? Icons.calendar_view_week 
                        : Icons.calendar_month,
                    size: 14,
                    color: textColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    period,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
