import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/mood_selector.dart';

class MoodScreen extends StatefulWidget {
  @override
  _MoodScreenState createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String selectedMood = "";
  String note = "";

  void _saveMood() async {
    if (selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Выберите настроение перед сохранением!")),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Ищем существующую запись настроения за сегодня
    QuerySnapshot moodSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moods")
        .where("timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    if (moodSnapshot.docs.isNotEmpty) {
      // Обновляем существующую запись
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
      // Создаём новую запись, если сегодня ещё не было
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
      selectedMood = "";
      note = "";
    });
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
            Text("Выберите ваше настроение:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            MoodSelector(
              selectedMood: selectedMood,
              onMoodSelected: (mood) {
                setState(() {
                  selectedMood = mood;
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
