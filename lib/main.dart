import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyDcO_c8cf_Nm7Mcbh3lnRGL3D7NgiLEgSE",
          authDomain: "emotion-todo.firebaseapp.com",
          projectId: "emotion-todo",
          storageBucket: "emotion-todo.firebasestorage.app",
          messagingSenderId: "1023214464565",
          appId: "1:1023214464565:web:9e54b36c747a126f5d4b7c",
          measurementId: "G-6SCH8WHJS4"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true, // Включаем кэш Firestore
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'task_channel',
        channelName: 'Task Reminders',
        channelDescription: 'Напоминания о задачах',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );

  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(
      // DevicePreview(
      //     builder: (context) =>
              MyApp()//)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MainScreen(user: snapshot.data!);
          } else {
            return AuthScreen();
          }
        },
      ),
    );
  }
}

