import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final Function(String, String) onModelSelected; // Callback to pass both model and fruit name
  const Home({super.key, required this.onModelSelected});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<bool> switchStates = List.generate(5, (_) => false);
  
  List<Map<String, String>> fruits = [
    {"name": "Pisang", "image": "assets/pisang.png", "model": "assets/model/banana.tflite"},
    {"name": "Jeruk", "image": "assets/jeruk.png", "model": "assets/model/orange.tflite"},
    {"name": "Mangga", "image": "assets/mangga.png", "model": "assets/model/mango.tflite"},
    {"name": "Jambu", "image": "assets/guava.png", "model": "assets/model/guava.tflite"},
    {"name": "Tomat", "image": "assets/tomat.png", "model": "assets/model/tomato.tflite"},
  ];

  void toggleSwitch(int index) {
    setState(() {
      // Update the switch states
      for (int i = 0; i < switchStates.length; i++) {
        switchStates[i] = (i == index); // Only allow one switch on at a time
      }

      // Pass the selected model and fruit name to the parent (MainScreen)
      widget.onModelSelected(fruits[index]["model"]!, fruits[index]["name"]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 30),
                child: Text(
                  'Pilih Buah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int i = 0; i < fruits.length; i++)
                        Container(
                          width: 300,
                          height: 100,
                          margin: EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image(
                                    image: AssetImage(fruits[i]["image"]!),
                                    width: 50,
                                    height: 50,
                                  ),
                                  Text(
                                    fruits[i]["name"]!,
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                  ),
                                  Switch(
                                    activeColor: Colors.amber,
                                    activeTrackColor: Colors.cyan,
                                    inactiveThumbColor: Colors.blueGrey.shade600,
                                    inactiveTrackColor: Colors.grey.shade400,
                                    splashRadius: 50.0,
                                    value: switchStates[i],
                                    onChanged: (value) {
                                      if (value) {
                                        toggleSwitch(i); // Update the selected fruit model and name
                                      } else {
                                        // Allow turning off the switch
                                        setState(() {
                                          switchStates[i] = false; // Set this switch off
                                        });
                                        widget.onModelSelected('', ''); // Clear the model and fruit name
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
