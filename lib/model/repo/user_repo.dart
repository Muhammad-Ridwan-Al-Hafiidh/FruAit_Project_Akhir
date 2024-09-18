import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fruait/model/model/users_model.dart';
import 'package:get/get.dart';

class UserRepo extends GetxController {
  static UserRepo get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  createUser(UserModel user) async {
    await _db.collection("Users").add(user.toJson()).then(
      (value) {
        Get.snackbar(
          "Success", 
          "Your account is created.", 
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      },
    ).catchError((error) {
      Get.snackbar(
        "Error", 
        "Something went wrong.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
      print(error.toString());
    });
  }
}
