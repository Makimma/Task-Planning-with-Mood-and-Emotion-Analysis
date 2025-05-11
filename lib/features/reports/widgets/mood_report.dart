import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../../moods/widgets/mood_chart.dart';
import 'task_chart.dart';
import 'productivity_chart.dart';

class MoodReport extends StatelessWidget {
  final ReportModel? reportData;
  final String selectedPeriod;
  final bool isLoading;

  const MoodReport({
    Key? key,
    required this.reportData,
    required this.selectedPeriod,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (reportData == null) {
      return Center(child: Text('Нет данных'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodHistory(context),
            SizedBox(height: 24),
            _buildTaskDistribution(context),
            SizedBox(height: 24),
            _buildProductivityAnalysis(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHistory(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "История настроения",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 200,
              maxHeight: 300,
            ),
            child: reportData!.moodData.isEmpty
                ? _buildEmptyState(
                    context,
                    Icons.sentiment_neutral,
                    "Нет данных за этот период",
                  )
                : MoodChart(moodData: reportData!.moodData),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDistribution(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Распределение выполненных задач",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 500,
              maxHeight: 700,
            ),
            child: reportData!.categoryCounts.isEmpty && reportData!.priorityCounts.isEmpty
                ? _buildEmptyState(
                    context,
                    Icons.task_alt,
                    "Нет данных о задачах",
                  )
                : TaskCharts(
                    categoryCounts: reportData!.categoryCounts,
                    priorityCounts: reportData!.priorityCounts,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityAnalysis(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Продуктивность по настроению",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 700,
            child: reportData!.moodProductivity.isEmpty
                ? _buildEmptyState(
                    context,
                    Icons.analytics,
                    "Нет данных для анализа",
                  )
                : ProductivityChart(
                    moodProductivity: reportData!.moodProductivity,
                    productivityInsights: reportData!.productivityInsights,
                    getTaskWord: _getTaskWord,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getTaskWord(double count) {
    if (count == 1) return "задача";
    if (count > 1 && count < 5) return "задачи";
    return "задач";
  }
} 