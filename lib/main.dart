import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash/splash_screen.dart';
import 'package:vitals_pro/services/ble_manager.dart';
import 'package:vitals_pro/services/vitals_recorder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize BLE
  await BleManager().initialize();

  // Start automatic recording
  VitalsRecorder.start();

  runApp(const VitalsProApp());
}

class VitalsProApp extends StatelessWidget {
  const VitalsProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitals Pro',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F2027),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.cyanAccent,
        ),
      ),

      // 🔥 APP STARTS HERE
      home: const SplashScreen(),
    );
  }
}