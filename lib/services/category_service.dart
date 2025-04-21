import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://language.googleapis.com/v2/documents:classifyText?key=$_apiKey";

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

  static Future<String?> classifyText(String text) async {
    final requestBody = {
      "document": {
        "type": "PLAIN_TEXT",
        "content": text
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['categories'] != null && jsonResponse['categories'].isNotEmpty) {
          final categories = jsonResponse['categories'] as List;
          final topCategory = categories.first['name'] as String;
          final mappedCategory = _mapGoogleCategory(topCategory);
          return mappedCategory;
        }
      }
    } catch (e) {
      // throw Exception("Ошибка: ${e.toString()}");
      throw Exception("Что-то пошло не так");
    }
    
    return 'Другое';
  }
}
