import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://translation.googleapis.com/language/translate/v2?key=$_apiKey";

  static Future<String?> translateText(String text, String targetLang) async {
    final Map<String, dynamic> requestBody = {
      "q": text,
      "target": targetLang,
      "format": "text",
      "source": "ru"
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["data"]["translations"][0]["translatedText"];
    } else {
      return null;
    }
  }
}
