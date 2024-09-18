import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fruait/model/model/history_model.dart';

class ImageService {
  Future<List<ImagesModel>> getImagesForUser(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('user_id', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ImagesModel(
          url: data['url'],
          buah: data['buah'],
          result: data['result'], 
          userId: data['user_id'],
        );
      }).toList();
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }
}
