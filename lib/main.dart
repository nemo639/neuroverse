import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroverse/features/Home/home.dart';
import 'package:neuroverse/features/auth/login.dart';
import 'package:neuroverse/features/auth/register.dart';
import 'package:neuroverse/features/auth/forgot_password_screen.dart';
import 'package:neuroverse/features/auth/otp-verification.dart';
import 'package:neuroverse/features/profile/profile.dart';
import 'package:neuroverse/features/profile/edit_profile.dart';
import 'package:neuroverse/features/labs/testsscreen.dart';
import 'package:neuroverse/features/labs/speech_language_test.dart';
import 'package:neuroverse/features/labs/cognitive_memory_test.dart';
import 'package:neuroverse/features/labs/motor_functions_test.dart';
import 'package:neuroverse/features/labs/gait_movement_test.dart';
import 'package:neuroverse/features/report/reports_screen.dart';
import 'package:neuroverse/features/xai/xai.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF5F5F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeuroVerse',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        fontFamily: 'SF Pro',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/otp-verification': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(
            email: args?['email'] ?? '',
            verificationType: args?['type'] ?? 'signup',
          );
        },
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/tests': (context) => const TestsScreen(),
        '/test/speech-language': (context) => const SpeechLanguageTestScreen(),
        '/test/cognitive-memory': (context) => const CognitiveMemoryTestScreen(),
        '/test/motor-functions': (context) => const MotorFunctionsTestScreen(),
        '/test/gait-movement': (context) => const GaitMovementTestScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/XAI': (context) => const XAIScreen(),
      },
    );
  }
}