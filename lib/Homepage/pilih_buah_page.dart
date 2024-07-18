import 'package:flutter/material.dart';
import 'package:fruait/main_screen/main_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<bool> switchStates = List.generate(5, (_) => false);
  
  List<Map<String, String>> fruits = [
    {"name": "Pisang", "image": "assets/pisang.png"},
    {"name": "jeruk", "image": "assets/jeruk.png"},
    {"name": "Mangga", "image": "assets/mangga.png"},
    {"name": "jambu", "image": "assets/guava.png"},
    {"name": "tomat", "image": "assets/tomat.png"},
  ];

  void toggleSwitch(int index) {
    setState(() {
      for (int i = 0; i < switchStates.length; i++) {
        switchStates[i] = (i == index);
      }
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
                                    height: 50
                                  ),
                                  Text(
                                    fruits[i]["name"]!,
                                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)
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
                                        toggleSwitch(i);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Text('data')
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