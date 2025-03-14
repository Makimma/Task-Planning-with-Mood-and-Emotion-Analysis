import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://language.googleapis.com/v1/documents:classifyText?key=$_apiKey";

  static Future<String?> classifyText(String text) async {
    final requestBody = {
      "document": {
        "type": "PLAIN_TEXT",
        "content": text,
        "language": "en"
      }
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List categories = data["categories"];

      if (categories.isNotEmpty) {
        return categories[0]["name"].split('/').last; // Берём самую релевантную категорию
      }
    } else {
      print("Ошибка: ${response.body}");
    }
    return null;
  }
}
