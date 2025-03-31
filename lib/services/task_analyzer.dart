import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../services/nlp_service.dart';
import '../services/translation_service.dart';
import '../constants/task_constants.dart';

class TaskAnalyzer {
  static Future<void> analyzeCategory({
    required String title,
    required String comment,
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        onError('⚠️ Нет интернет-соединения');
        return;
      }

      final formattedTitle = title.trim().endsWith('.') ? title.trim() : "${title.trim()}.";
      final fullText = "$formattedTitle $comment";

      if (fullText.split(RegExp(r'\s+')).length < 20) {
        onError('Добавьте больше деталей, минимум 20 слов');
        return;
      }

      final translatedText = await TranslationService.translateText(fullText, "en");
      if (translatedText == null) {
        onError('Ошибка перевода текста');
        return;
      }

      final category = await CategoryService.classifyText(translatedText);
      final resolvedCategory = _resolveCategory(category);

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
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        onError('⚠️ Нет интернет-соединения');
        return;
      }

      final formattedTitle = title.trim().endsWith('.') ? title.trim() : "${title.trim()}.";
      final fullText = "$formattedTitle $comment";

      final sentiment = await NaturalLanguageService.analyzeSentiment(fullText);
      if (sentiment == null) {
        onError('Ошибка анализа эмоциональной нагрузки');
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
    if (score >= 0.5 && magnitude < 1.5) return 1;
    if (score >= 0.2 && magnitude < 2.0) return 2;
    if (-0.2 <= score && score < 0.2) return 3;
    if (-0.5 <= score && score < -0.2 && magnitude >= 1.0) return 4;
    return 5;
  }

  static void _handleError(dynamic error, Function(String) onError) {
    if (error is SocketException) {
      onError('📡 Ошибка подключения к серверу');
    } else if (error is TimeoutException) {
      onError('⏳ Превышено время ожидания');
    } else {
      onError('❌ Ошибка: ${error.toString().split(':').first}');
    }
  }
}