import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fruait/Homepage/history.dart';
import 'package:fruait/Homepage/kamera.dart';
import 'package:fruait/Homepage/pilih_buah_page.dart';

// MainScreen widget
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MainScreen(cameras: cameras));
}

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainScreen({super.key, required this.cameras});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentTab = 0;
  late PageController _pageController;

  // Variable to store the selected model
  String selectedModelPath = 'assets/model/banana.tflite'; // Default model
  String selectedFruit = 'Pisang'; // Example selected fruit from the switch.

  // Callback to handle model and fruit name selection
  void onModelSelected(String model, String fruitName) {
    setState(() {
      selectedModelPath = model; // Update the model based on user selection in Home
      selectedFruit = fruitName; // Update the fruit name
    });
  }


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentTab);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void onPageChanged(int index) {
    setState(() {
      currentTab = index;
    });
  }

  void onTabTapped(int index) {
    setState(() {
      currentTab = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 22, 21, 21),
        elevation: 0,
        shape: CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: Container(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  MaterialButton(
                    onPressed: () => onTabTapped(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apple_rounded,
                          color: currentTab == 0 ? Colors.white : Colors.grey,
                        ),
                        Text(
                          'Buah',
                          style: TextStyle(color: currentTab == 0 ? Colors.white : Colors.grey),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MaterialButton(
                    onPressed: () => onTabTapped(1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: currentTab == 1 ? Colors.white : Colors.grey,
                        ),
                        Text(
                          'History',
                          style: TextStyle(color: currentTab == 1 ? Colors.white : Colors.grey),
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(0, 255, 255, 255).withOpacity(0.95),
      floatingActionButton: FloatingActionButton(
        elevation: 3,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => MainPage(cameras: widget.cameras, modelPath: selectedModelPath,selectedFruit: selectedFruit,)),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: Color.fromARGB(255, 205, 245, 237),
        child: const Image(image: AssetImage('assets/logo.png'), width: 45, height: 45),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: PageView(
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: [
          Home(onModelSelected: onModelSelected), // Pass the callback directly
          History(),
        ],
      ),
    );
  }
}
