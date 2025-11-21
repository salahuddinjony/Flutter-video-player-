import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';
import 'controllers/video_player_controller.dart';
import 'controllers/instruction_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('Note: Firebase configuration files may be missing.');
    print('The app will work in offline mode with local instructions.');
    // App can still work with local instructions if Firebase fails
  }

  // Orientation is now free - app can rotate to any orientation
  // No orientation lock is set

  // Initialize GetX controllers
  Get.put(VideoPlayerController());
  Get.put(InstructionController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
