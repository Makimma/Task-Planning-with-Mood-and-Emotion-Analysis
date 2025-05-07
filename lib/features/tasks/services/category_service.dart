import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  static String _mapGoogleCategory(String googleCategory) {
    const categoryMap = {
      // Работа
      'work': 'Работа',
      'business': 'Работа',
      'industrial': 'Работа',
      'productivity': 'Работа',
      'management': 'Работа',
      'reports': 'Работа',
      'sales': 'Работа',
      'marketing': 'Работа',

      // Учёба
      'education': 'Учёба',
      'exam': 'Учёба',
      'university': 'Учёба',
      'study': 'Учёба',
      'science': 'Учёба',
      'mathematics': 'Учёба',
      'physics': 'Учёба',
      'chemistry': 'Учёба',
      'biology': 'Учёба',

      // Финансы
      'finance': 'Финансы',
      'investing': 'Финансы',
      'stocks': 'Финансы',
      'budget': 'Финансы',

      // Здоровье и спорт
      'health': 'Здоровье и спорт',
      'fitness': 'Здоровье и спорт',
      'nutrition': 'Здоровье и спорт',
      'yoga': 'Здоровье и спорт',

      // Развитие и хобби
      'hobbies': 'Развитие и хобби',
      'programming': 'Развитие и хобби',
      'language': 'Развитие и хобби',
      'books': 'Развитие и хобби',

      // Личное
      'personal': 'Личное',
      'family': 'Личное',
      'relationships': 'Личное',

      // Домашние дела
      'home': 'Домашние дела',
      'repair': 'Домашние дела',
      'cleaning': 'Домашние дела',
      'garden': 'Домашние дела',
      'kitchen': 'Домашние дела',
      'dining': 'Домашние дела',

      // Путешествия и досуг
      'travel': 'Путешествия и досуг',
      'tourism': 'Путешествия и досуг',
      'vacation': 'Путешествия и досуг',
    };

    // Нормализация с разделением слов
    final normalizedCategory = googleCategory
        .replaceAll('&', ' ') // Заменяем & на пробел
        .replaceAll(RegExp(r'[^a-zA-Z/ ]'), '') // Удаляем спецсимволы, кроме пробела и /
        .toLowerCase()
        .split(RegExp(r'[/ ]')) // Разбиваем по / и пробелам
        .where((part) => part.isNotEmpty)
        .toList();

    for (final part in normalizedCategory) {
      // Проверка по ключевым словам
      if (part.contains('home') || part.contains('repair') || part.contains('cleaning')) {
        return 'Домашние дела';
      }

      // Проверка по точным совпадениям
      if (categoryMap.containsKey(part)) {
        return categoryMap[part]!;
      }
    }

    return 'Другое';
  }

  static Future<String> classifyText(String text) async {
    const endpoint = "https://tiny-hill-7228.fam-ivan2003.workers.dev/classify";
    if (text.trim().isEmpty) return 'Другое';

    final resp = await http
        .post(Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception("Proxy ${resp.statusCode}: ${resp.body}");
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final categories = data['categories'] as List<dynamic>?;

    if (categories == null || categories.isEmpty) return 'Другое';

    final googleName = categories.first['name'] as String;
    return _mapGoogleCategory(googleName);
  }
}
