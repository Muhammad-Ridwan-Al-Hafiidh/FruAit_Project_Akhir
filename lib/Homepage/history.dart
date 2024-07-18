import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'history_detail.dart'; // Import your detail page

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<bool> switchStates = List.generate(5, (_) => false);

  List<Map<String, String>> fruits = [
    {"name": "Pisang", "icon": "assets/pisang.png", "status": "ripe", "image": "assets/background.png"},
    {"name": "Jeruk", "icon": "assets/jeruk.png", "status": "half-ripe", "image": "assets/background.png"},
    {"name": "Mangga", "icon": "assets/mangga.png", "status": "unripe" , "image": "assets/background.png"},
    {"name": "Jambu", "icon": "assets/guava.png", "status": "ripe", "image": "assets/background"},
    {"name": "Tomat", "icon": "assets/tomat.png", "status": "half-ripe", "image": "assets/background.png"},
  ];

  int? expandedIndex;

  void toggleExpansion(int index) {
    setState(() {
      if (expandedIndex == index) {
        expandedIndex = null;
      } else {
        expandedIndex = index;
      }
    });
  }

  void navigateToDetailPage(String name, String image, String status, String icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailPage(
          name: name,
          image: image,
          icon: icon,
          status: status,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 30),
                  child: Text(
                    'History Kematangan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 37,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: fruits.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => toggleExpansion(index),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                width: screenWidth * 0.9,
                                height: screenHeight * 0.2,
                                child: Card(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                           Image(
                                        image:
                                            AssetImage(fruits[index]["icon"]!),
                                        width: 50,
                                        height: 50,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        fruits[index]["name"]!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('data'),
                                              Text('data')
                                            ],
                                          ),
                                        ],
                                      )
                                     
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: expandedIndex == index,
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: expandedIndex == index ? 16 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => navigateToDetailPage(
                                        fruits[index]["name"]!,
                                        fruits[index]["icon"]!,
                                        fruits[index]["status"]!,
                                        fruits[index]["image"]!,
                                      ),
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Status: ${fruits[index]["status"]}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
