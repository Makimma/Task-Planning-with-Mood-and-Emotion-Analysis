import 'dart:convert';
import 'package:http/http.dart' as http;

class NLPService {
  static const String _apiKey = "ТВОЙ_API_КЛЮЧ"; // Вставь свой API-ключ
  static const String _url =  "https://language.googleapis.com/v1/documents:analyzeSentiment?key=$_apiKey";

  static Future<double> analyzeSentiment(String text) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "document": {
          "type": "PLAIN_TEXT",
          "content": text,
        },
        "encodingType": "UTF8",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["documentSentiment"]["score"]; // Возвращает значение от -1 до 1
    } else {
      throw Exception("Ошибка запроса NLP API");
    }
  }
}
