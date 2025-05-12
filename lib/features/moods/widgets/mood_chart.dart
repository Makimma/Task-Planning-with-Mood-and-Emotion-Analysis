import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'gradient_mood_icon.dart';

class MoodChart extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodChart({required this.moodData, Key? key}) : super(key: key);

  int _moodToYValue(String mood) {
    Map<String, int> moodMapping = {
      "Радость": 1,
      "Спокойствие": 2,
      "Усталость": 3,
      "Грусть": 4,
    };
    return moodMapping[mood] ?? 2;
  }

  Color _getMoodColor(String mood) {
    Map<String, Color> moodColors = {
      "Радость": Color(0xFFFFD93D), // Желтый
      "Спокойствие": Color(0xFF4CAF50), // Зеленый
      "Усталость": Color(0xFFFF5252), // Красный
      "Грусть": Color(0xFF7E57C2), // Фиолетовый
    };
    return moodColors[mood] ?? Colors.grey;
  }
  
  Widget _buildCustomMarker(String mood, double size) {
    final color = _getMoodColor(mood);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            spreadRadius: 0.5,
          )
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDarkMode ? Colors.white24 : Colors.black12;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    if (moodData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              "Нет данных о настроении",
              style: TextStyle(
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.only(left: 10, right: 10),
      constraints: BoxConstraints.expand(height: 250),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ось Y с иконками настроений
          Container(
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMoodAxisLabel("Грусть"),
                _buildMoodAxisLabel("Усталость"),
                _buildMoodAxisLabel("Спокойствие"),
                _buildMoodAxisLabel("Радость"),
              ].reversed.toList(), // Разворачиваем список, чтобы Радость была внизу
            ),
          ),
          SizedBox(width: 8),
          // График
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(double.infinity, 210),
                  painter: ChartGridPainter(
                    gridColor: gridColor,
                    moodData: moodData,
                    textColor: textColor,
                  ),
                ),
                ..._buildMarkers(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAxisLabel(String mood) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: GradientMoodIcon(
        mood: mood,
        size: 24,
      ),
    );
  }

  List<Widget> _buildMarkers(BuildContext context) {
    final List<Widget> markers = [];
    final chartHeight = 160.0; // Высота области графика
    final cellHeight = chartHeight / 4; // Высота одной клетки
    
    for (int i = 0; i < moodData.length; i++) {
      final data = moodData[i];
      final mood = data["mood"];
      final yValue = _moodToYValue(mood);
      
      // Вычисляем позицию Y с учетом высоты графика
      // Добавляем половину высоты клетки для смещения вниз
      final yPosition = (cellHeight * (yValue - 1)) + (cellHeight / 2);
      
      markers.add(
        Positioned(
          left: moodData.length == 1 
              ? ((300 - 40) / 2) 
              : (i / (moodData.length - 1)) * (300 - 40),
          top: yPosition - 8, // Центрируем маркер (-8 это половина размера маркера)
          child: GestureDetector(
            onTap: () {
              final dateStr = DateFormat('dd MMMM').format(data["date"]);
              final note = data["note"] ?? "Нет комментария";
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildCustomMarker(mood, 16),
                          SizedBox(width: 8),
                          Text(
                            mood,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        note,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: _buildCustomMarker(mood, 16),
          ),
        )
      );
    }
    return markers;
  }
}

class ChartGridPainter extends CustomPainter {
  final Color gridColor;
  final List<Map<String, dynamic>> moodData;
  final Color textColor;

  ChartGridPainter({
    required this.gridColor, 
    required this.moodData,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Горизонтальные линии
    for (int i = 1; i <= 4; i++) {
      final dashPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      // Рисуем пунктирную линию
      for (double x = 0; x < size.width; x += 10.0) {
        canvas.drawLine(
          Offset(x, i * 40),
          Offset(x + 5, i * 40),
          dashPaint,
        );
      }
    }
    
    // Вертикальные линии и надписи дат
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    
    final monthStyle = TextStyle(
      fontSize: 12,
      color: textColor.withOpacity(0.6),
    );
    
    int step = (moodData.length <= 10) ? 1 : 2;
    
    for (int i = 0; i < moodData.length; i += step) {
      if (i >= moodData.length) continue;
      
      // Расчет позиции
      final x = moodData.length == 1 
          ? size.width / 2 
          : (i / (moodData.length - 1)) * size.width;
      
      // Рисуем пунктирную вертикальную линию
      for (double y = 0; y < 160; y += 10.0) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 5),
          paint,
        );
      }
      
      // Даты внизу
      final date = moodData[i]["date"] as DateTime;
      final dayText = DateFormat('dd').format(date);
      final monthText = DateFormat('MMM').format(date);
      
      final dayPainter = TextPainter(
        text: TextSpan(text: dayText, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      
      final monthPainter = TextPainter(
        text: TextSpan(text: monthText, style: monthStyle),
        textDirection: ui.TextDirection.ltr,
      );
      
      dayPainter.layout();
      monthPainter.layout();
      
      dayPainter.paint(
        canvas, 
        Offset(x - dayPainter.width / 2, 170),
      );
      
      monthPainter.paint(
        canvas, 
        Offset(x - monthPainter.width / 2, 170 + dayPainter.height + 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
