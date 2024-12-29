import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import the generated firebase_options.dart file
import 'login_page.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // Use generated options for each platform
    );
    runApp(const SafetyGuideApp());
  } catch (e) {
    print("Firebase Initialization Error: $e");
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child:
              Text('Firebase Initialization Failed. Please restart the app.'),
        ),
      ),
    ));
  }
}

class SafetyGuideApp extends StatelessWidget {
  const SafetyGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Safety Guide',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}
