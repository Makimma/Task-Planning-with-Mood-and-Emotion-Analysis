import 'package:flutter/material.dart';
import '../data/reports_data_provider.dart';
import '../../../core/widgets/report_card.dart';
import '../../moods/widgets/gradient_mood_icon.dart';
import 'mood_stat_card.dart';
import 'task_stat_row.dart';

class OverviewReport extends StatelessWidget {
  final ReportsDataProvider dataProvider;
  final String selectedPeriod;
  final bool isLoading;

  const OverviewReport({
    Key? key,
    required this.dataProvider,
    required this.selectedPeriod,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    int displayedTasks = selectedPeriod == "Неделя" 
        ? dataProvider.tasksThisWeek 
        : dataProvider.tasksThisMonth;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodOverview(context),
            SizedBox(height: 24),
            _buildTasksOverview(context, displayedTasks),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOverview(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.05)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Среднее настроение",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              GradientMoodIcon(
                mood: dataProvider.dominantMood,
                size: 40,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Преобладающее настроение: ${dataProvider.dominantMood}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (dataProvider.moodChangePercentage != 0) ...[
                      SizedBox(height: 4),
                      Text(
                        dataProvider.moodChangePercentage > 0
                            ? "На ${dataProvider.moodChangePercentage.abs().toStringAsFixed(1)}% лучше, чем в прошлый ${selectedPeriod.toLowerCase()}"
                            : "На ${dataProvider.moodChangePercentage.abs().toStringAsFixed(1)}% хуже, чем в прошлый ${selectedPeriod.toLowerCase()}",
                        style: TextStyle(
                          fontSize: 14,
                          color: dataProvider.moodChangePercentage > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    if (dataProvider.mostProductiveDay != "Нет данных") ...[
                      SizedBox(height: 4),
                      Text(
                        "Лучший день недели: ${dataProvider.mostProductiveDay}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MoodStatCard(
                  title: "Позитивные дни",
                  value: "${dataProvider.positiveDaysPercentage.toStringAsFixed(1)}%",
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MoodStatCard(
                  title: "Негативные дни",
                  value: "${dataProvider.negativeDaysPercentage.toStringAsFixed(1)}%",
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksOverview(BuildContext context, int displayedTasks) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.transparent : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.05)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Выполненные задачи",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          ReportCard(
            title: selectedPeriod == "Неделя" ? "За неделю" : "За месяц",
            count: displayedTasks,
            suffix: dataProvider.getTaskWord(displayedTasks.toDouble()),
          ),
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskStatRow(
                label: "В среднем в день:",
                value: "${dataProvider.averageTasksPerDay.toStringAsFixed(1)} ${dataProvider.getTaskWord(dataProvider.averageTasksPerDay)}",
              ),
              if (dataProvider.mostProductiveDayForTasks != "Нет данных")
                TaskStatRow(
                  label: "Самый продуктивный день:",
                  value: dataProvider.mostProductiveDayForTasks,
                ),
              TaskStatRow(
                label: "Сравнение:",
                value: dataProvider.getComparisonText(),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 