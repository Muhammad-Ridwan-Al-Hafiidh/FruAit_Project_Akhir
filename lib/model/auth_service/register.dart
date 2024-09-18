import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fruait/model/auth_service/firebase_auth_services.dart';
import 'package:fruait/model/auth_service/firebase_controller/controller.dart';
import 'package:fruait/model/auth_service/login.dart';
import 'package:fruait/model/auth_service/toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(Regis(cameras: cameras));
}

class Regis extends StatefulWidget {
  final List<CameraDescription> cameras;
  const Regis({super.key, required this.cameras});
  @override
  State<Regis> createState() => _RegisState();
}

class _RegisState extends State<Regis> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Register Your Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                FormContainerWidget(
                  controller: _emailController,
                  hintText: 'Enter Your Email',
                  isPasswordField: false,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                FormContainerWidget(
                  controller: _usernameController,
                  hintText: 'Username',
                  isPasswordField: false,
                  inputType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                FormContainerWidget(
                  controller: _passwordController,
                  hintText: 'Password',
                  isPasswordField: true,
                  inputType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sudah Punya Akun? ",
                      style: TextStyle(color: Colors.white54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginDulu(cameras: widget.cameras)));
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

   void _signUp() async {
  setState(() {
    isSigningUp = true;
  });

  String username = _usernameController.text;
  String email = _emailController.text;
  String password = _passwordController.text;

  // Sign up the user with Firebase Authentication
  User? user = await _auth.signUpWithEmailAndPassword(email, password);

  setState(() {
    isSigningUp = false;
  });

  if (user != null) {
    // Store user details in Firestore
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'username': username,
      'email': email,
      'createdAt': Timestamp.now(),
    });

    Fluttertoast.showToast(
      msg: "User successfully created",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    // Navigate to login page after successful registration
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginDulu(cameras: widget.cameras)),
    );
  } else {
    Fluttertoast.showToast(
      msg: "An error occurred during registration",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}
}