import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fruait/splashscreen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyChVciAk7lpw0Gzcqu8h5hG662MYJgsF0k",
        appId: "1:760794668113:android:d5b939805011414da8ec70",
        messagingSenderId: "760794668113",
        projectId: "fruait-da351",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  final cameras = await availableCameras();
  runApp(MainApp(cameras: cameras));
}

class MainApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MainApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(cameras: cameras),
    );
  }
}