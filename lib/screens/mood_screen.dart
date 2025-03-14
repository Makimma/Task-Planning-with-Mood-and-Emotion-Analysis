import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/nlp_service.dart';
import '../services/translation_service.dart';
import '../widgets/mood_selector.dart';

class MoodScreen extends StatefulWidget {
  @override
  _MoodScreenState createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String selectedMood = "";
  String note = "";
  String currentMood = "Настроение не выбрано";

  @override
  void initState() {
    super.initState();
    _fetchCurrentMood();
  }

  void _fetchCurrentMood() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    QuerySnapshot moodSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moods")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (moodSnapshot.docs.isNotEmpty) {
      setState(() {
        currentMood = moodSnapshot.docs.first["type"];
      });
    }
  }

  void _saveMood() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Если настроение не выбрано, анализируем заметку
    if (selectedMood.isEmpty && note.isNotEmpty) {
      setState(() {
        currentMood = "Определяем настроение...";
      });

      // Переводим заметку на английский
      String? translatedText = await TranslationService.translateText(note, "en");
      if (translatedText == null) {
        setState(() {
          currentMood = "Ошибка перевода!";
        });
        return;
      }

      // Анализируем настроение (получаем `score` и `magnitude`)
      Map<String, double>? sentimentResult = await NaturalLanguageService.analyzeSentiment(translatedText);
      if (sentimentResult != null) {
        double score = sentimentResult["score"]!;
        double magnitude = sentimentResult["magnitude"]!;
        selectedMood = _mapSentimentToMood(score, magnitude);
      } else {
        setState(() {
          currentMood = "Ошибка анализа настроения!";
        });
        return;
      }
    }

    // Проверяем, что хотя бы что-то определилось
    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Выберите настроение перед сохранением!")),
      );
      return;
    }

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    QuerySnapshot moodSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moods")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (moodSnapshot.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("moods")
          .doc(moodSnapshot.docs.first.id)
          .update({
        "type": selectedMood,
        "note": note,
        "timestamp": Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Настроение обновлено!")),
      );
    } else {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("moods")
          .add({
        "type": selectedMood,
        "note": note,
        "timestamp": Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Настроение сохранено!")),
      );
    }

    setState(() {
      currentMood = selectedMood;
      selectedMood = "";
      note = "";
    });
  }

  String _mapSentimentToMood(double score, double magnitude) {
    if (score < -0.5 && magnitude >= 1.0) {
      return "Грусть";
    }
    if (score >= 0.5 && magnitude < 3.0) {
      return "Радость";
    }
    if (score <= -0.3 && magnitude >= 0.5 && magnitude < 1.5) {
      return "Усталость";
    }
    return "Спокойствие";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настроение")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Текущее настроение:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.mood, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      currentMood,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Выберите ваше настроение:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            MoodSelector(
              selectedMood: selectedMood,
              onMoodSelected: (mood) {
                setState(() {
                  if (selectedMood == mood) {
                    selectedMood = ""; // Снимаем выбор, если нажали повторно
                  } else {
                    selectedMood = mood;
                  }
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              maxLength: 512,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Текстовая заметка",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  note = value;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveMood,
                child: Text("Сохранить"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
