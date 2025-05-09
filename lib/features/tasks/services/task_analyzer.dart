import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'category_service.dart';
import '../../../core/services/nlp_service.dart';
import '../../../constants/task_constants.dart';

class TaskAnalyzer {
  static Future<void> analyzeCategory({
    required String title,
    required String comment,
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    // Check if both fields are empty or contain only whitespace
    final trimmedTitle = title.trim();
    final trimmedComment = comment.trim();
    if (trimmedTitle.isEmpty && trimmedComment.isEmpty) {
      onError('Введите название или комментарий для анализа');
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        onError('Отсутствует подключение к интернету');
        return;
      }

      final formattedTitle = trimmedTitle.endsWith('.') ? trimmedTitle : "$trimmedTitle.";
      final fullText = "$formattedTitle $trimmedComment";

      final response = await CategoryService.classifyText(fullText);
      final resolvedCategory = _resolveCategory(response);
      onSuccess(resolvedCategory);
    } catch (e) {
      _handleError(e, onError);
    }
  }

  static Future<void> analyzeEmotionalLoad({
    required String title,
    required String comment,
    required BuildContext context,
    required Function(int) onSuccess,
    required Function(String) onError,
  }) async {
    // Check if both fields are empty or contain only whitespace
    final trimmedTitle = title.trim();
    final trimmedComment = comment.trim();
    if (trimmedTitle.isEmpty && trimmedComment.isEmpty) {
      onError('Введите название или комментарий для анализа');
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        onError('Отсутствует подключение к интернету');
        return;
      }

      final formattedTitle = trimmedTitle.endsWith('.') ? trimmedTitle : "$trimmedTitle.";
      final fullText = "$formattedTitle $trimmedComment";

      final sentiment = await NaturalLanguageService.analyzeSentiment(fullText);
      if (sentiment == null) {
        onError('Не удалось определить эмоциональную нагрузку');
        return;
      }

      final loadLevel = _convertSentimentToLoad(
        sentiment["score"]!,
        sentiment["magnitude"]!,
      );

      onSuccess(loadLevel);
    } catch (e) {
      _handleError(e, onError);
    }
  }

  static String _resolveCategory(String? category) {
    if (category != null && TaskConstants.categories.contains(category)) {
      return category;
    }
    return "Другое";
  }

  static int _convertSentimentToLoad(double score, double magnitude) {
    int load;

    if (magnitude < 0.05) {
      load = 1;
    } else if (magnitude < 0.10) {
      load = 2;
    } else if (magnitude < 0.15) {
      load = 3;
    } else if (magnitude < 0.20) {
      load = 4;
    } else {
      load = 5;
    }

    if (score >= 0.3 && load > 1) {
      load--;
    }
    else if (score <= -0.3 && load < 5) {
      load++;
    }

    return load;
  }


  //TODO
  static void _handleError(dynamic error, Function(String) onError) {
    if (error is SocketException) {
      onError('Сервер недоступен. Проверьте подключение 🌐');
    } else if (error is TimeoutException) {
      onError('Сервер не отвечает. Попробуйте позже ⏳');
    } else {
      final errorMessage = error.toString().split(':').first;
      if (errorMessage.contains('Exception')) {
        onError('Произошла ошибка при анализе 😕');
      } else {
        onError('Что-то пошло не так. Попробуйте еще раз 🔄');
      }
    }
  }
}