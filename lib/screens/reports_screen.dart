import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = "Неделя";
  int tasksToday = 0;
  int tasksThisWeek = 0;
  int tasksThisMonth = 0;
  List<Map<String, dynamic>> moodData = [];

  @override
  void initState() {
    super.initState();
    _fetchTaskCounts();
    _fetchMoodHistory();
  }

  void _fetchTaskCounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    int todayCount = await _getCompletedTasks(
        user.uid, DateTime(now.year, now.month, now.day));
    int weekCount = await _getCompletedTasks(user.uid, startDate);
    int monthCount =
        await _getCompletedTasks(user.uid, DateTime(now.year, now.month, 1));

    setState(() {
      tasksToday = todayCount;
      tasksThisWeek = weekCount;
      tasksThisMonth = monthCount;
    });
  }

  Future<int> _getCompletedTasks(String userId, DateTime startDate) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .get();

    return snapshot.docs.where((doc) {
      Timestamp completedAt = doc['completedAt'] as Timestamp;
      return completedAt.toDate().isAfter(startDate);
    }).length;
  }

  void _fetchMoodHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startDate = selectedPeriod == "Неделя"
        ? now.subtract(Duration(days: 7))
        : now.subtract(Duration(days: 30));

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      moodData = snapshot.docs.map((doc) {
        return {
          "date": (doc['timestamp'] as Timestamp).toDate(),
          "mood": doc['type'],
          "note": doc['note'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Отчёты"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Задачи"),
              Tab(text: "Настроение"),
            ],
          ),
          actions: [
            DropdownButton<String>(
              value: selectedPeriod,
              items: ["Неделя", "Месяц"].map((String period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPeriod = value!;
                  _fetchTaskCounts();
                  _fetchMoodHistory();
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTaskReport(),
            _buildMoodReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskReport() {
    int displayedTasks = selectedPeriod == "Неделя"
        ? tasksThisWeek
        : tasksThisMonth;

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Выполненные задачи:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildReportCard(
              selectedPeriod == "Неделя" ? "За неделю" : "За месяц",
              displayedTasks),
        ],
      ),
    );
  }

  Widget _buildMoodReport() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: moodData.isEmpty
          ? Center(child: Text("Нет данных за этот период"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("График настроения:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Flexible(
                  fit: FlexFit.loose,
                  child: _buildMoodChart(),
                ),
              ],
            ),
    );
  }

  Widget _buildMoodChart() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.only(left: 10, right: 10),
      constraints: BoxConstraints.expand(height: 250),
      child: LineChart(
        LineChartData(
          minY: 0.5,
          maxY: 4.5,
          titlesData: FlTitlesData(
            // Убираем ВСЕ верхние и правые подписи
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Настраиваем левую ось (только эмодзи)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value < 1 || value > 4)
                    return Container(); // Скрываем дробные значения
                  Map<int, String> emojiLabels = {
                    1: "😢",
                    2: "😫",
                    3: "😌",
                    4: "😊",
                  };
                  return Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Text(emojiLabels[value.toInt()]!,
                        style: TextStyle(fontSize: 20)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2, // Показываем подписи через день
                reservedSize: 40, // Добавляем место для двухстрочных подписей
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= moodData.length) return Container();

                  DateTime date = moodData[value.toInt()]["date"];
                  return Padding(
                    padding: EdgeInsets.only(top: 5), // Отступ от оси X
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd').format(date),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            DateFormat('MMMM').format(date),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: moodData.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> data = entry.value;
                return FlSpot(
                    index.toDouble(), _moodToYValue(data["mood"]).toDouble());
              }).toList(),
              isCurved: true,
              dotData: FlDotData(show: true),
              color: Colors.blue,
              barWidth: 3,
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  int index = spot.x.toInt();
                  Map<String, dynamic> data = moodData[index];

                  String dateStr = DateFormat('dd.MM').format(data["date"]);
                  String note = data["note"] ?? "Нет комментария";

                  return LineTooltipItem(
                    "$dateStr\n$note",
                    TextStyle(color: Colors.white, fontSize: 14),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  int _moodToYValue(String mood) {
    Map<String, int> moodMapping = {
      "Радость": 4,
      "Спокойствие": 3,
      "Усталость": 2,
      "Грусть": 1,
    };
    return moodMapping[mood] ?? 2;
  }

  Widget _buildReportCard(String title, int count) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("$count",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
