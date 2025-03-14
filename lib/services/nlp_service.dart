import 'dart:convert';
import 'package:http/http.dart' as http;

class NaturalLanguageService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://language.googleapis.com/v1/documents:analyzeSentiment?key=$_apiKey";

  static Future<Map<String, double>?> analyzeSentiment(String text) async {
    final Map<String, dynamic> requestBody = {
      "document": {
        "type": "PLAIN_TEXT",
        "content": text,
        "language": "en"
      },
      "encodingType": "UTF8",
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "score": data["documentSentiment"]["score"],
        "magnitude": data["documentSentiment"]["magnitude"],
      };
    } else {
      print("Ошибка: ${response.body}");
      return null;
    }
  }
}
