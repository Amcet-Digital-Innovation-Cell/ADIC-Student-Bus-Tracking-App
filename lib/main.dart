import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/theme_controller.dart'; // or your path to theme_controller.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore saved dark/light mode preference from local storage
  await AppTheme.initTheme();

  runApp(const StudentBusApp());
}

class StudentBusApp extends StatelessWidget {
  const StudentBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'AMCET Transport',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: AppTheme.bgSurface(isDark),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
          },
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
        );
      },
    );
  }
}