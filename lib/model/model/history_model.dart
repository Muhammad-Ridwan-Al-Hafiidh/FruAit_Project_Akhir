// Update your ImagesModel class
class ImagesModel {
  final String? buah;
  final String userId;
  final String url;
  final String? result;

  ImagesModel({
    required this.buah,
    required this.userId,
    required this.url,
    this.result,
  });

  factory ImagesModel.fromJson(Map<String, dynamic> json) {
    return ImagesModel(
      buah: json['buah'] as String?,
      userId: json['user_id'] as String,
      url: json['url'] as String,
      result: json['result'] as String?,
    );
  }

  @override
  String toString() {
    return 'ImagesModel(buah: $buah, userId: $userId, url: $url, result: $result)';
  }
}