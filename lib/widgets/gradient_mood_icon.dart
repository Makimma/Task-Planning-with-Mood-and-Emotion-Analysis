import 'package:flutter/material.dart';

class GradientMoodIcon extends StatelessWidget {
  final String mood;
  final double size;
  final bool isSelected;

  const GradientMoodIcon({
    Key? key,
    required this.mood,
    this.size = 40,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _getGradientColors().first.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Icon(
        _getMoodIcon(),
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (mood) {
      case "Радость":
        return [
          Color(0xFFFFD700), // Золотой
          Color(0xFFFF8C00), // Оранжевый
        ];
      case "Грусть":
        return [
          Color(0xFF4169E1), // Синий
          Color(0xFF8A2BE2), // Фиолетовый
        ];
      case "Спокойствие":
        return [
          Color(0xFF32CD32), // Зеленый
          Color(0xFF20B2AA), // Бирюзовый
        ];
      case "Усталость":
        return [
          Color(0xFFFF4500), // Красно-оранжевый
          Color(0xFFDC143C), // Темно-красный
        ];
      default:
        return [
          Colors.grey.shade400,
          Colors.grey.shade600,
        ];
    }
  }

  IconData _getMoodIcon() {
    switch (mood) {
      case "Радость":
        return Icons.wb_sunny_rounded;
      case "Грусть":
        return Icons.cloud_rounded;
      case "Спокойствие":
        return Icons.nightlight_round;
      case "Усталость":
        return Icons.bedtime_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
} 