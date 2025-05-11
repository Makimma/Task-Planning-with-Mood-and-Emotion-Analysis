class ReportModel {
  final int tasksThisWeek;
  final int tasksThisMonth;
  final int previousPeriodTasks;
  final double taskChangePercentage;
  final List<Map<String, dynamic>> moodData;
  final String dominantMood;
  final double positiveDaysPercentage;
  final double negativeDaysPercentage;
  final Map<String, int> categoryCounts;
  final Map<String, int> priorityCounts;
  final Map<String, int> moodProductivity;
  final String mostProductiveMood;
  final double mostProductiveMoodRate;
  final List<String> productivityInsights;
  final double moodChangePercentage;
  final String mostProductiveDay;
  final double averageTasksPerDay;
  final String mostProductiveDayForTasks;
  final int totalTasksCount;
  final double taskCompletionRate;

  ReportModel({
    required this.tasksThisWeek,
    required this.tasksThisMonth,
    required this.previousPeriodTasks,
    required this.taskChangePercentage,
    required this.moodData,
    required this.dominantMood,
    required this.positiveDaysPercentage,
    required this.negativeDaysPercentage,
    required this.categoryCounts,
    required this.priorityCounts,
    required this.moodProductivity,
    required this.mostProductiveMood,
    required this.mostProductiveMoodRate,
    required this.productivityInsights,
    required this.moodChangePercentage,
    required this.mostProductiveDay,
    required this.averageTasksPerDay,
    required this.mostProductiveDayForTasks,
    required this.totalTasksCount,
    required this.taskCompletionRate,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      tasksThisWeek: map['tasksThisWeek'] ?? 0,
      tasksThisMonth: map['tasksThisMonth'] ?? 0,
      previousPeriodTasks: map['previousPeriodTasks'] ?? 0,
      taskChangePercentage: map['taskChangePercentage']?.toDouble() ?? 0.0,
      moodData: List<Map<String, dynamic>>.from(map['moodData'] ?? []),
      dominantMood: map['dominantMood'] ?? 'Нет данных',
      positiveDaysPercentage: map['positiveDaysPercentage']?.toDouble() ?? 0.0,
      negativeDaysPercentage: map['negativeDaysPercentage']?.toDouble() ?? 0.0,
      categoryCounts: Map<String, int>.from(map['categoryCounts'] ?? {}),
      priorityCounts: Map<String, int>.from(map['priorityCounts'] ?? {}),
      moodProductivity: Map<String, int>.from(map['moodProductivity'] ?? {}),
      mostProductiveMood: map['mostProductiveMood'] ?? 'Нет данных',
      mostProductiveMoodRate: map['mostProductiveMoodRate']?.toDouble() ?? 0.0,
      productivityInsights: List<String>.from(map['productivityInsights'] ?? []),
      moodChangePercentage: map['moodChangePercentage']?.toDouble() ?? 0.0,
      mostProductiveDay: map['mostProductiveDay'] ?? 'Нет данных',
      averageTasksPerDay: map['averageTasksPerDay']?.toDouble() ?? 0.0,
      mostProductiveDayForTasks: map['mostProductiveDayForTasks'] ?? 'Нет данных',
      totalTasksCount: map['totalTasksCount'] ?? 0,
      taskCompletionRate: map['taskCompletionRate']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tasksThisWeek': tasksThisWeek,
      'tasksThisMonth': tasksThisMonth,
      'previousPeriodTasks': previousPeriodTasks,
      'taskChangePercentage': taskChangePercentage,
      'moodData': moodData,
      'dominantMood': dominantMood,
      'positiveDaysPercentage': positiveDaysPercentage,
      'negativeDaysPercentage': negativeDaysPercentage,
      'categoryCounts': categoryCounts,
      'priorityCounts': priorityCounts,
      'moodProductivity': moodProductivity,
      'mostProductiveMood': mostProductiveMood,
      'mostProductiveMoodRate': mostProductiveMoodRate,
      'productivityInsights': productivityInsights,
      'moodChangePercentage': moodChangePercentage,
      'mostProductiveDay': mostProductiveDay,
      'averageTasksPerDay': averageTasksPerDay,
      'mostProductiveDayForTasks': mostProductiveDayForTasks,
      'totalTasksCount': totalTasksCount,
      'taskCompletionRate': taskCompletionRate,
    };
  }
} 