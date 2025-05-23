import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'core/navigation/main_screen.dart';
import 'core/di/service_locator.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/reports/viewmodels/report_viewmodel.dart';

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

  // Инициализация DI
  await ServiceLocator.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = _parseThemeMode(theme);
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    setState(() {
      _themeMode = mode;
    });
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<ReportViewModel>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFF5F5F7),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.black87),
            elevation: 0,
          ),
          cardColor: Colors.white,
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
            background: Color(0xFFF5F5F7),
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black87,
            onBackground: Colors.black87,
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.black87),
            titleMedium: TextStyle(color: Colors.black),
          ),
          dividerColor: Colors.grey[300],
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardColor: Colors.grey[850],
          colorScheme: ColorScheme.dark(
            primary: Colors.blueAccent,
            secondary: Colors.blueGrey,
            background: Colors.black,
            surface: Colors.grey[800]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.white70),
            titleMedium: TextStyle(color: Colors.white),
          ),
        ),
        themeMode: _themeMode,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              return MainScreen(user: snapshot.data!);
            }
            
            return AuthScreen();
          },
        ),
      ),
    );
  }
}
