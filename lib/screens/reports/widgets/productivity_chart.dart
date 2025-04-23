import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductivityChart extends StatelessWidget {
  final Map<String, int> moodProductivity;
  final List<String> productivityInsights;
  final String Function(double) getTaskWord;

  const ProductivityChart({
    Key? key,
    required this.moodProductivity,
    required this.productivityInsights,
    required this.getTaskWord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (productivityInsights.isNotEmpty) ...[
          _buildInsightsCard(context),
          SizedBox(height: 24),
        ],
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  enabled: true,
                ),
                borderData: FlBorderData(show: false),
              ),
              swapAnimationDuration: Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeInOutQuart,
            ),
          ),
        ),
        SizedBox(height: 32),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(context, "Радость", Colors.green),
              _buildLegendItem(context, "Спокойствие", Colors.blue),
              _buildLegendItem(context, "Усталость", Colors.orange),
              _buildLegendItem(context, "Грусть", Colors.purple),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Анализ продуктивности",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 12),
          ...productivityInsights.map((insight) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = moodProductivity.values.fold(0, (a, b) => a + b);
    return moodProductivity.entries.map((entry) {
      final double percent = total > 0 ? (entry.value / total * 100) : 0;
      final color = _getMoodColor(entry.key);
      return PieChartSectionData(
        value: percent,
        color: color,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(BuildContext context, String mood, Color color) {
    final count = moodProductivity[mood] ?? 0;
    final total = moodProductivity.values.fold(0, (a, b) => a + b);
    final percent = total > 0 ? (count / total * 100) : 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                mood,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            SizedBox(height: 4),
            Text(
              '$count ${getTaskWord(count.toDouble())} (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case "Радость":
        return Colors.green;
      case "Спокойствие":
        return Colors.blue;
      case "Усталость":
        return Colors.orange;
      case "Грусть":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
} 