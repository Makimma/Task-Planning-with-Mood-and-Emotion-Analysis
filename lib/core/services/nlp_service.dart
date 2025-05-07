import 'dart:convert';
import 'package:http/http.dart' as http;

class NaturalLanguageService {
  static Future<Map<String, double>?> analyzeSentiment(String text) async {
    const endpoint = "https://tiny-hill-7228.fam-ivan2003.workers.dev/sentiment";
    final t = text.trim();
    if (t.isEmpty) return {"score": 0.0, "magnitude": 0.0};

    try {
      final r = await http
          .post(Uri.parse(endpoint),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"text": t}))
          .timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {
          "score": (data["documentSentiment"]["score"] as num).toDouble(),
          "magnitude": (data["documentSentiment"]["magnitude"] as num).toDouble(),
        };
      } else {
        throw Exception("Sentiment proxy ${r.statusCode}: ${r.body}");
      }
    } catch (e) {
      throw Exception("Sentiment error: $e");
    }
  }

  static Future<String?> analyzeMood(String text) async {
    const String endpoint = "https://tiny-hill-7228.fam-ivan2003.workers.dev/mood";
    if (text.trim().isEmpty) return null;

    try {
      final r = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (r.statusCode == 200) {
        final decoded = utf8.decode(r.bodyBytes);
        final mood = (jsonDecode(decoded)["mood"] as String)
            .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
            .trim();

        const moods = {"Радость", "Спокойствие", "Грусть", "Усталость"};
        return moods.contains(mood) ? mood : "Спокойствие";
      } else {
        // для отладки
        print("Mood proxy HTTP ${r.statusCode}: ${r.body}");
      }
    } catch (e) {
      print("Exception in analyzeMood: $e");
    }
    return null;
  }
}
