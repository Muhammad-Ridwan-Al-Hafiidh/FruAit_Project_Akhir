import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:external_path/external_path.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:gap/gap.dart';

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  File? _image;
  late Interpreter _interpreter;
  List<String> _labels = ["Banana", "Orange", "Pen", "Sticky Notes"];
  bool _isRearCamera = true;
  bool _isFlashOn = false;
  List<File> _imagesList = [];

  String _result = "";
  List<double> _confidence = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
  }

  void _switchCamera() {
    setState(() {
      _isRearCamera = !_isRearCamera;
      int cameraIndex = _isRearCamera ? 0 : 1;
      _cameraController = CameraController(
        widget.cameras[cameraIndex],
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _cameraController.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  Future<File> _saveImage(XFile image) async {
    final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('$downloadPath/$fileName');

    try {
      await file.writeAsBytes(await image.readAsBytes());
    } catch (e) {
      print('Error saving image: $e');
    }

    return file;
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController.takePicture();
      final savedImage = await _saveImage(image);
      setState(() {
        _image = savedImage;
        _imagesList.add(savedImage);
      });
      MediaScanner.loadMedia(path: savedImage.path);
      _classifyImage();
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imagesList.add(_image!);
      });
      _classifyImage();
    }
  }

  Future<void> _classifyImage() async {
  if (_image == null) return;

  img.Image imageInput = img.decodeImage(_image!.readAsBytesSync())!;
  var resizedImage = img.copyResize(imageInput, width: 224, height: 224);

  var inputBytes = Float32List(1 * 224 * 224 * 3);
  var inputShape = [1, 224, 224, 3];
  var outputShape = [1, 4];

  int pixelIndex = 0;
  for (var y = 0; y < 224; y++) {
    for (var x = 0; x < 224; x++) {
      var pixel = resizedImage.getPixel(x, y);
      inputBytes[pixelIndex++] = pixel.r / 255.0;  // Red
      inputBytes[pixelIndex++] = pixel.g / 255.0;  // Green
      inputBytes[pixelIndex++] = pixel.b / 255.0;  // Blue
    }
  }

  var outputBytes = List<double>.filled(1 * 4, 0).reshape(outputShape);
  _interpreter.run(inputBytes.reshape(inputShape), outputBytes);

  var results = outputBytes[0];
  var maxScore = results.reduce((a, b) => a > b ? a : b);
  var maxIndex = results.indexOf(maxScore);

  setState(() {
    _result = _labels[maxIndex];
    _confidence = results.map((e) => e * 100).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_cameraController);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 60,
                  child: Card(
                    color: Color.fromARGB(102, 0, 0, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _toggleFlash,
                            child: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          GestureDetector(
                            onTap: _switchCamera,
                            child: Icon(
                              _isRearCamera ? Icons.camera_rear : Icons.camera_front,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
                if (_image != null)
                  Column(
                    children: [
                      Text('Classified as: $_result', style: TextStyle(color: Colors.white, fontSize: 20)),
                      for (int i = 0; i < _labels.length; i++)
                        Text('${_labels[i]}: ${_confidence[i].toStringAsFixed(1)}%', 
                             style: TextStyle(color: Colors.white)),
                    ],
                  ),
                SizedBox(height: 20),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagesList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _imagesList[index],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _interpreter.close();
    super.dispose();
  }
}