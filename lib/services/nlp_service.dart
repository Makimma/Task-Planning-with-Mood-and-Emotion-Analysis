import 'dart:convert';
import 'package:http/http.dart' as http;

class NaturalLanguageService {
  static const String _apiKey = "AIzaSyCWimDE_6lk378H3VMBPegyoMu6soDQxv4";
  static const String _baseUrl = "https://language.googleapis.com/v2/documents:analyzeSentiment?key=$_apiKey";

  static Future<Map<String, double>?> analyzeSentiment(String text) async {
    final Map<String, dynamic> requestBody = {
      "document": {
        "type": "PLAIN_TEXT",
        "content": text,
      },
      "encodingType": "UTF8",
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "score": (data["documentSentiment"]["score"] as num).toDouble(),
        "magnitude": (data["documentSentiment"]["magnitude"] as num).toDouble(),
      };
    }
    return null;
  }
}
