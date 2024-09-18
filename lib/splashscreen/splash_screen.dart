import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fruait/model/auth_service/login.dart';

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SplashScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(Duration(seconds: 3), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginDulu(cameras: widget.cameras)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',  // Make sure to add your logo image to the assets folder
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              'Fruait',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}