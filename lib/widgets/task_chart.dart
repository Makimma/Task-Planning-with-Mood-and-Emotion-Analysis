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
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildCategoryChart(),
        ),
        SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'По приоритету',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _buildPriorityChart(),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
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
                final category = categoryCounts.keys.elementAt(group.x.toInt());
                return BarTooltipItem(
                  '$category\n${rod.toY.toStringAsFixed(1)}%',
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
                  final category = categoryCounts.keys.elementAt(value.toInt());
                  return Transform.rotate(
                    angle: 0,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        _shortenLabel(category),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black,
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
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildPriorityChart() {
    final total = priorityCounts.values.fold(0, (a, b) => a + b);
    final sections = priorityCounts.entries.map((entry) {
      final double percent = total > 0 ? (entry.value / total * 100) : 0;
      return PieChartSectionData(
        value: percent,
        color: _getPriorityColor(entry.key),
        title: '${percent.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return SizedBox(
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
    );
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
}
