import 'dart:convert';
import 'package:http/http.dart' as http;

class NaturalLanguageService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://language.googleapis.com/v1/documents:analyzeSentiment?key=$_apiKey";

  static Future<double?> analyzeSentiment(String text) async {
    final Map<String, dynamic> requestBody = {
      "document": {
        "type": "PLAIN_TEXT",
        "content": text,
        "language": "en"
      },
      "encodingType": "UTF8",
    };

    print("📢 Отправляем запрос: $requestBody");

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print("📢 Код ответа: ${response.statusCode}");
    print("📢 Тело ответа: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["documentSentiment"]["score"];
    } else {
      print("❌ Ошибка API: ${response.body}");
      return null;
    }
  }
}
