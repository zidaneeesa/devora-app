import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Jangan await ApiConfig dan NotificationService di sini
  // supaya SplashScreen Dart langsung tampil
  runApp(const DevoraApp());
}

class DevoraApp extends StatefulWidget {
  const DevoraApp({super.key});

  @override
  State<DevoraApp> createState() => _DevoraAppState();
}

class _DevoraAppState extends State<DevoraApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // SplashScreen Dart sudah tampil saat proses ini berjalan
      await ApiConfig.init();
      await NotificationService.init();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Durasi splash Dart
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      setState(() {
        _isAuthenticated = token != null;
        _isLoading = false;
      });
    } catch (e) {
      // Tetap tunggu agar splash screen tidak hilang secara instan jika error
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMA NEGERI 4 JEMBER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7FAF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B5A41),
          primary: const Color(0xFF2B5A41),
          secondary: const Color(0xFFE4F1E8),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF8),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF2B5A41)),
          titleTextStyle: TextStyle(
            color: Color(0xFF2B5A41),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF679B7B),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F4F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const SplashScreen()
          : _isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}