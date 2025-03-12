import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodChart({required this.moodData, Key? key}) : super(key: key);

  int _moodToYValue(String mood) {
    Map<String, int> moodMapping = {
      "Радость": 4,
      "Спокойствие": 3,
      "Усталость": 2,
      "Грусть": 1,
    };
    return moodMapping[mood] ?? 2;
  }

  @override
  Widget build(BuildContext context) {
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
                return FlSpot(index.toDouble(), _moodToYValue(data["mood"]).toDouble());
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
}
