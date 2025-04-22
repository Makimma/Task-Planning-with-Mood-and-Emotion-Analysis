import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TaskCharts extends StatelessWidget {
  final Map<String, int> categoryCounts;
  final Map<String, int> priorityCounts;

  static final List<Color> _categoryColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
    Colors.brown,
  ];

  const TaskCharts({
    required this.categoryCounts,
    required this.priorityCounts,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'По категориям',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildCategoryChart(context),
        ),
        SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'По приоритету',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildPriorityChart(context),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(BuildContext context) {
    final total = categoryCounts.values.fold(0, (a, b) => a + b);

    final sortedEntries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bars = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      final double percent = total > 0 ? (value / total * 100) : 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percent,
            color: _getCategoryColor(index),
            width: 20,
            borderSide: BorderSide.none,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
        ],
        showingTooltipIndicators: [],
      );
    }).toList();

    return Container(
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final category = sortedEntries[group.x.toInt()].key;
                final value = sortedEntries[group.x.toInt()].value;
                return BarTooltipItem(
                  '$category\n$value ${_getTaskWord(value)} (${rod.toY.toStringAsFixed(1)}%)',
                  TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final category = sortedEntries[value.toInt()].key;
                  return Transform.rotate(
                    angle: 0,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        _shortenLabel(category),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1,
              ),
              left: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          barGroups: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          maxY: 100,
        ),
      ),
    );
  }

  Widget _buildPriorityChart(BuildContext context) {
    final total = priorityCounts.values.fold(0, (a, b) => a + b);
    final sections = priorityCounts.entries.map((entry) {
      final double percent = total > 0 ? (entry.value / total * 100) : 0;
      return PieChartSectionData(
        value: percent,
        color: _getPriorityColor(entry.key),
        title: '',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildPriorityLegend(context),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPriorityLegend(BuildContext context) {
    final Map<String, String> priorityLabels = {
      'high': 'Высокий',
      'medium': 'Средний',
      'low': 'Низкий',
    };

    final total = priorityCounts.values.fold(0, (a, b) => a + b);
    
    return priorityCounts.entries.map((entry) {
      final percent = total > 0 ? (entry.value / total * 100) : 0;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getPriorityColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priorityLabels[entry.key] ?? entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${entry.value} ${_getTaskWord(entry.value)} (${percent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _shortenLabel(String original) {
    const maxLength = 8;
    if (original.length <= maxLength) return original;
    return '${original.substring(0, maxLength)}...';
  }

  String _getTaskWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'задача';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'задачи';
    } else {
      return 'задач';
    }
  }
}
