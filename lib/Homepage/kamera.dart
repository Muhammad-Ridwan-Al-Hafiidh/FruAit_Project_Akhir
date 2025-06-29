import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fruait/Homepage/Detail_Image.dart';
import 'package:path/path.dart' as Path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';

// RGB Range class for custom criteria
class RGBRange {
  final int minR, maxR, minG, maxG, minB, maxB;
  
  RGBRange({
    required this.minR, required this.maxR,
    required this.minG, required this.maxG,
    required this.minB, required this.maxB,
  });
}

class ColorCluster {
  int pixelCount = 0;
  double totalR = 0;
  double totalG = 0;
  double totalB = 0;
  
  double get avgR => totalR / pixelCount;
  double get avgG => totalG / pixelCount;
  double get avgB => totalB / pixelCount;
  
  void addPixel(int r, int g, int b) {
    totalR += r;
    totalG += g;
    totalB += b;
    pixelCount++;
  }
}

// Fruit criteria class
class FruitCriteria {
  final String fruitName;
  final Map<String, RGBRange> ripenessRanges;
  
  FruitCriteria({
    required this.fruitName,
    required this.ripenessRanges,
  });
}

// Color data class to represent each color from CSV
class ColorData {
  final String colorName;
  final String hexValue;
  final int r;
  final int g;
  final int b;

  ColorData({
    required this.colorName,
    required this.hexValue,
    required this.r,
    required this.g,
    required this.b,
  });
}

// Enhanced weighted color cluster class
class WeightedColorCluster {
  int pixelCount = 0;
  double totalR = 0;
  double totalG = 0;
  double totalB = 0;
  double totalWeight = 0;
  
  double get avgR => totalR / totalWeight;
  double get avgG => totalG / totalWeight;
  double get avgB => totalB / totalWeight;
  double get weightedScore => totalWeight; // Use total weight as score
  
  void addPixel(int r, int g, int b, double weight) {
    totalR += r * weight;
    totalG += g * weight;
    totalB += b * weight;
    totalWeight += weight;
    pixelCount++;
  }
}

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String modelPath;
  final String selectedFruit;

  const MainPage({
    Key? key,
    required this.cameras,
    required this.modelPath,
    required this.selectedFruit,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  File? _image;
  late Interpreter _interpreter;
  List<String> _labels = ["Matang", "Setengah Matang", "Belum Matang"];
  bool _isRearCamera = true;
  bool _isFlashOn = false;
  List<File> _imagesList = [];
  String _result = "";
  List<double> _confidence = [];
  final int imageSize = 224;
  
  // Color detection variables - NOW ENABLED BY DEFAULT
  List<ColorData> _colorDatabase = [];
  String _detectedColor = "";
  Color _dominantColor = Colors.transparent;
  bool _isColorDetectionEnabled = true; // Changed from false to true
  
  // Custom criteria variables
  Map<String, FruitCriteria> _fruitCriteria = {};
  String _customRipenessResult = "";
  bool _useCustomCriteria = false;
  double _criteriaConfidence = 0.0;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 4.0;
  
  bool _isProcessingImage = false;
 

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  _initializeEverything();
}

Future<void> _initializeEverything() async {
  _initializeControllerFuture = _initializeCamera();

  await _initializeControllerFuture; // Tunggu kamera selesai inisialisasi

  _minAvailableZoom = await _cameraController.getMinZoomLevel();
  _maxAvailableZoom = await _cameraController.getMaxZoomLevel();

  _loadModel();
  _loadColorDatabase();
  _initializeFruitCriteria();

  setState(() {}); // Untuk memastikan UI diperbarui setelah semua siap
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeControllerFuture = _initializeCamera();
    }
  }

  // Initialize custom fruit criteria based on your tables
  void _initializeFruitCriteria() {
    _fruitCriteria = {
      'Jeruk Valencia': FruitCriteria(
        fruitName: 'Jeruk Valencia',
        ripenessRanges: {
          'Belum Matang': RGBRange(minR: 183, maxR: 202, minG: 139, maxG: 168, minB: 83, maxB: 120),
          'Setengah Matang': RGBRange(minR: 128, maxR: 152, minG: 128, maxG: 142, minB: 85, maxB: 100),
          'Matang': RGBRange(minR: 104, maxR: 131, minG: 124, maxG: 144, minB: 80, maxB: 115),
        },
      ),
      'Mangga Golek': FruitCriteria(
        fruitName: 'Mangga Golek',
        ripenessRanges: {
          'Belum Matang': RGBRange(minR: 0, maxR: 30, minG: 57, maxG: 99, minB: 43, maxB: 100),
          'Setengah Matang': RGBRange(minR: 28, maxR: 64, minG: 27, maxG: 69, minB: 20, maxB: 58),
          'Matang': RGBRange(minR: 50, maxR: 100, minG: 0, maxG: 35, minB: 0, maxB: 34),
        },
      ),
      'Tomat Buah': FruitCriteria(
        fruitName: 'Tomat Buah',
        ripenessRanges: {
          'Belum Matang': RGBRange(minR: 21, maxR: 23, minG: 21, maxG: 22, minB: 17, maxB: 20),
          'Setengah Matang': RGBRange(minR: 8, maxR: 25, minG: 13, maxG: 22, minB: 19, maxB: 29),
          'Matang': RGBRange(minR: 7, maxR: 24, minG: 15, maxG: 21, minB: 3, maxB: 20),
        },
      ),
      'Pisang Cavendish': FruitCriteria(
        fruitName: 'Pisang Cavendish',
        ripenessRanges: {
          'Belum Matang': RGBRange(minR: 0, maxR: 29, minG: 59, maxG: 100, minB: 45, maxB: 99),
          'Setengah Matang': RGBRange(minR: 27, maxR: 60, minG: 26, maxG: 67, minB: 29, maxB: 57),
          'Matang': RGBRange(minR: 54, maxR: 100, minG: 0, maxG: 58, minB: 0, maxB: 32),
        },
      ),
      'Jambu Biji Merah': FruitCriteria(
        fruitName: 'Jambu Biji Merah',
        ripenessRanges: {
          'Belum Matang': RGBRange(minR: 62, maxR: 120, minG: 75, maxG: 123, minB: 23, maxB: 55),
          'Setengah Matang': RGBRange(minR: 62, maxR: 145, minG: 75, maxG: 146, minB: 23, maxB: 75),
          'Matang': RGBRange(minR: 120, maxR: 255, minG: 123, maxG: 255, minB: 55, maxB: 255),
        },
      ),
    };
    
    if (kDebugMode) {
      print("Custom fruit criteria initialized for ${_fruitCriteria.length} fruits");
    }
  }

  // Check if RGB values fall within a specific range
  bool _isRGBInRange(int r, int g, int b, RGBRange range) {
    return r >= range.minR && r <= range.maxR &&
           g >= range.minG && g <= range.maxG &&
           b >= range.minB && b <= range.maxB;
  }

  // Determine ripeness based on custom criteria
  String _determineRipenessFromRGB(String fruitName, int r, int g, int b) {
    if (!_fruitCriteria.containsKey(fruitName)) {
      return "Unknown Fruit";
    }
    
    FruitCriteria criteria = _fruitCriteria[fruitName]!;
    Map<String, double> scores = {};
    
    // Calculate distance-based scores for each ripeness category
    criteria.ripenessRanges.forEach((ripeness, range) {
      // Calculate distance from the center of each range
      int centerR = (range.minR + range.maxR) ~/ 2;
      int centerG = (range.minG + range.maxG) ~/ 2;
      int centerB = (range.minB + range.maxB) ~/ 2;
      
      double distance = ((r - centerR).abs() + (g - centerG).abs() + (b - centerB).abs()).toDouble();
      
      // Check if within range
      if (_isRGBInRange(r, g, b, range)) {
        scores[ripeness] = 100.0; // Perfect match
      } else {
        // Calculate inverse distance score (closer = higher score)
        scores[ripeness] = 100.0 / (1.0 + distance / 50.0);
      }
    });
    
    // Find the category with highest score
    String bestMatch = "Unknown";
    double highestScore = 0.0;
    
    scores.forEach((ripeness, score) {
      if (score > highestScore) {
        highestScore = score;
        bestMatch = ripeness;
      }
    });
    
    setState(() {
      _criteriaConfidence = highestScore;
    });
    
    return bestMatch;
  }

  // Apply custom criteria to image
  Future<void> _applyCustomCriteria(File imageFile) async {
    try {
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return;
      
      // Get dominant color
      Color dominantColor = await getDominantColor(image);
      
      // Determine ripeness based on custom criteria
      String customResult = _determineRipenessFromRGB(
        widget.selectedFruit,
        dominantColor.red,
        dominantColor.green,
        dominantColor.blue,
      );
      
      setState(() {
        _customRipenessResult = customResult;
        _dominantColor = dominantColor;
      });
      
      if (kDebugMode) {
        print("Custom criteria result: $customResult (Confidence: ${_criteriaConfidence.toStringAsFixed(1)}%)");
        print("Dominant color RGB: ${dominantColor.r}, ${dominantColor.g}, ${dominantColor.b}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error applying custom criteria: $e");
      }
    }
  }

  // Load color database from CSV file in assets
  Future<void> _loadColorDatabase() async {
    try {
      final String csvData = await rootBundle.loadString('assets/data/colors.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      _colorDatabase = csvTable.map((row) {
        return ColorData(
          colorName: row[1].toString(),
          hexValue: row[2].toString(),
          r: int.parse(row[3].toString()),
          g: int.parse(row[4].toString()),
          b: int.parse(row[5].toString()),
        );
      }).toList();
      
      if (kDebugMode) {
        print("Color database loaded: ${_colorDatabase.length} colors");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading color database: $e");
      }
    }
  }

 String getBasicColorName(int r, int g, int b) {
  // Define basic color ranges
  Map<String, Map<String, int>> basicColors = {
    'Red': {'r': 255, 'g': 0, 'b': 0},
    'Green': {'r': 0, 'g': 255, 'b': 0},
    'Blue': {'r': 0, 'g': 0, 'b': 255},
    'Yellow': {'r': 255, 'g': 255, 'b': 0},
    'Orange': {'r': 255, 'g': 165, 'b': 0},
    'Purple': {'r': 128, 'g': 0, 'b': 128},
    'Pink': {'r': 255, 'g': 192, 'b': 203},
    'Brown': {'r': 165, 'g': 42, 'b': 42},
    'Black': {'r': 0, 'g': 0, 'b': 0},
    'White': {'r': 255, 'g': 255, 'b': 255},
    'Gray': {'r': 128, 'g': 128, 'b': 128},
    'Lime': {'r': 0, 'g': 255, 'b': 0},
    'Maroon': {'r': 128, 'g': 0, 'b': 0},
    'Navy': {'r': 0, 'g': 0, 'b': 128},
    'Olive': {'r': 128, 'g': 128, 'b': 0},
    'Cyan': {'r': 0, 'g': 255, 'b': 255},
    'Magenta': {'r': 255, 'g': 0, 'b': 255},
    'Silver': {'r': 192, 'g': 192, 'b': 192},
    'Gold': {'r': 255, 'g': 215, 'b': 0},
    'Beige': {'r': 245, 'g': 245, 'b': 220},
  };

  double minDistance = double.infinity;
  String closestColor = "Unknown";

  basicColors.forEach((colorName, colorRgb) {
    double distance = ((r - colorRgb['r']!).abs() + 
                      (g - colorRgb['g']!).abs() + 
                      (b - colorRgb['b']!).abs()).toDouble();
    
    if (distance < minDistance) {
      minDistance = distance;
      closestColor = colorName;
    }
  });

  return closestColor;
}

// Enhanced function to get detailed color description
String getDetailedColorDescription(int r, int g, int b) {
  String basicColor = getBasicColorName(r, g, b);
  
  // Add brightness/saturation descriptors
  int brightness = ((r + g + b) / 3).round();
  int maxRgb = [r, g, b].reduce((a, b) => a > b ? a : b);
  int minRgb = [r, g, b].reduce((a, b) => a < b ? a : b);
  int saturation = maxRgb - minRgb;
  
  String descriptor = "";
  
  // Brightness descriptors
  if (brightness < 60) {
    descriptor += "Dark ";
  } else if (brightness > 200) {
    descriptor += "Light ";
  } else if (brightness > 160) {
    descriptor += "Bright ";
  }
  
  // Saturation descriptors
  if (saturation < 30) {
    descriptor += "Pale ";
  } else if (saturation > 150) {
    descriptor += "Vivid ";
  }
  
  return "$descriptor$basicColor".trim();
}

// Improved function to find the closest color name based on RGB values
String getColorName(int r, int g, int b) {
  // First try to match with CSV database if available
  if (_colorDatabase.isNotEmpty) {
    int minimum = 10000;
    String closestColorName = "Unknown";
    
    for (ColorData colorData in _colorDatabase) {
      int distance = (r - colorData.r).abs() + 
                    (g - colorData.g).abs() + 
                    (b - colorData.b).abs();
      
      if (distance <= minimum) {
        minimum = distance;
        closestColorName = colorData.colorName;
      }
    }
    
    // If the closest match is still too far, use basic color detection
    if (minimum > 150) {
      return getDetailedColorDescription(r, g, b);
    }
    
    return closestColorName;
  } else {
    // Fallback to basic color detection if CSV is not loaded
    return getDetailedColorDescription(r, g, b);
  }
}

// Enhanced dominant color extraction with improved center focus
Future<Color> getDominantColor(img.Image image) async {
  // Resize image for faster processing while maintaining quality
  img.Image resized = img.copyResize(image, width: 300, height: 300);
  
  // Define a smaller center area for more focused detection (30% of width and height)
  int centerWidth = (resized.width * 0.3).round();
  int centerHeight = (resized.height * 0.3).round();
  int startX = (resized.width - centerWidth) ~/ 2;
  int startY = (resized.height - centerHeight) ~/ 2;
  
  // Use weighted sampling - give more importance to pixels closer to center
  Map<String, WeightedColorCluster> colorClusters = {};
  
  for (int y = startY; y < startY + centerHeight; y++) {
    for (int x = startX; x < startX + centerWidth; x++) {
      img.Pixel pixel = resized.getPixel(x, y);
      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();
      
      // Skip very dark or very light pixels (likely shadows or highlights)
      int brightness = ((r + g + b) / 3).round();
      if (brightness < 25 || brightness > 235) {
        continue;
      }
      
      // Skip pixels with very low saturation (grays/whites)
      int maxChannel = [r, g, b].reduce(math.max);
      int minChannel = [r, g, b].reduce(math.min);
      int saturation = maxChannel - minChannel;
      if (saturation < 20) {
        continue;
      }
      
      // Calculate weight based on distance from center
      double centerX = startX + centerWidth / 2;
      double centerY = startY + centerHeight / 2;
      double distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
      double maxDistance = math.sqrt(math.pow(centerWidth / 2, 2) + math.pow(centerHeight / 2, 2));
      double weight = 1.0 - (distance / maxDistance); // Higher weight for center pixels
      weight = math.max(0.1, weight); // Minimum weight of 0.1
      
      // Create clusters with smaller tolerance for more precise color detection
      String clusterKey = '${(r / 15).round() * 15},${(g / 15).round() * 15},${(b / 15).round() * 15}';
      
      colorClusters.putIfAbsent(clusterKey, () => WeightedColorCluster());
      colorClusters[clusterKey]!.addPixel(r, g, b, weight);
    }
  }
  
  if (colorClusters.isEmpty) {
    // If no colors found in center, fall back to a slightly larger area
    return _fallbackCenterDominantColor(resized);
  }
  
  // Find the cluster with the highest weighted score
  WeightedColorCluster? dominantCluster;
  double maxScore = 0;
  
  colorClusters.forEach((key, cluster) {
    if (cluster.weightedScore > maxScore) {
      maxScore = cluster.weightedScore;
      dominantCluster = cluster;
    }
  });
 // After (fixed with null assertion):
if (dominantCluster != null && dominantCluster!.pixelCount > 0) {
  return Color.fromRGBO(
    dominantCluster!.avgR.round(),  // Safe: we know it's not null
    dominantCluster!.avgG.round(),
    dominantCluster!.avgB.round(),
    1.0
  );
}
  
  return Colors.grey;
}



// Fallback method with slightly larger center area
Color _fallbackCenterDominantColor(img.Image image) {
  // Use 50% of image for fallback (larger than primary method)
  int centerWidth = (image.width * 0.5).round();
  int centerHeight = (image.height * 0.5).round();
  int startX = (image.width - centerWidth) ~/ 2;
  int startY = (image.height - centerHeight) ~/ 2;
  
  Map<String, ColorCluster> colorClusters = {};
  
  for (int y = startY; y < startY + centerHeight; y++) {
    for (int x = startX; x < startX + centerWidth; x++) {
      img.Pixel pixel = image.getPixel(x, y);
      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();
      
      // Apply same filtering as main method
      int brightness = ((r + g + b) / 3).round();
      if (brightness < 25 || brightness > 235) continue;
      
      int maxChannel = [r, g, b].reduce(math.max);
      int minChannel = [r, g, b].reduce(math.min);
      int saturation = maxChannel - minChannel;
      if (saturation < 20) continue;
      
      String clusterKey = '${(r / 15).round() * 15},${(g / 15).round() * 15},${(b / 15).round() * 15}';
      
      colorClusters.putIfAbsent(clusterKey, () => ColorCluster());
      colorClusters[clusterKey]!.addPixel(r, g, b);
    }
  }
  
  ColorCluster? dominantCluster;
  int maxPixels = 0;
  
  colorClusters.forEach((key, cluster) {
    if (cluster.pixelCount > maxPixels) {
      maxPixels = cluster.pixelCount;
      dominantCluster = cluster;
    }
  });
  
 // After (fixed with null assertion):
if (dominantCluster != null && dominantCluster!.pixelCount > 0) {
  return Color.fromRGBO(
    dominantCluster!.avgR.round(),  // Safe: we know it's not null
    dominantCluster!.avgG.round(),
    dominantCluster!.avgB.round(),
    1.0
  );
}
  
  return Colors.grey;
}

// Enhanced color detection with more detailed output
Future<void> _detectColor(File imageFile) async {
  try {
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) return;
    
    Color dominantColor = await getDominantColor(image);
    String colorName = getColorName(
      dominantColor.red, 
      dominantColor.green, 
      dominantColor.blue
    );
    
    // Also get RGB string for display
    String rgbString = "RGB(${dominantColor.red}, ${dominantColor.green}, ${dominantColor.blue})";
    
    setState(() {
      _dominantColor = dominantColor;
      _detectedColor = "$colorName ($rgbString)";
    });
    
    if (kDebugMode) {
      print("Detected color: $colorName");
      print("RGB values: ${dominantColor.red}, ${dominantColor.green}, ${dominantColor.blue}");
      print("Hex: #${dominantColor.value.toRadixString(16).substring(2).toUpperCase()}");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error detecting color: $e");
    }
    // Fallback
    setState(() {
      _detectedColor = "Detection Error";
      _dominantColor = Colors.grey;
    });
  }
}

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[_isRearCamera ? 0 : 1],
      ResolutionPreset.high,
    );
    
    try {
      await _cameraController.initialize();
      await _cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing camera: $e");
      }
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    String fileName = Path.basename(imageFile.path);
    Reference storageReference = FirebaseStorage.instance.ref().child('images/$fileName');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.whenComplete(() => null);
    return await storageReference.getDownloadURL();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(widget.modelPath);
      if (kDebugMode) {
        print("Model loaded successfully from: ${widget.modelPath}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading model: $e");
      }
    }
  }

  void _switchCamera() {
    setState(() {
      _isRearCamera = !_isRearCamera;
      _initializeControllerFuture = _initializeCamera();
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _cameraController.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _toggleColorDetection() {
    setState(() {
      _isColorDetectionEnabled = !_isColorDetectionEnabled;
    });
  }

  void _toggleCustomCriteria() {
    setState(() {
      _useCustomCriteria = !_useCustomCriteria;
    });
  }

  Future<File> _saveImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '${directory.path}/$fileName';
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception('Failed to decode image');
    final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
    final file = File(filePath);
    await file.writeAsBytes(jpegBytes);
    return file;
  }

  Future<void> saveImageDetailsToFirestore(
      String imageUrl, String fruitName, String result, String userId, 
      {String? detectedColor, String? customResult, double? customConfidence}) async {
    Map<String, dynamic> data = {
      'url': imageUrl,
      'buah': fruitName,
      'result': result,
      'user_id': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    if (detectedColor != null) {
      data['detected_color'] = detectedColor;
    }
    
    if (customResult != null) {
      data['custom_criteria_result'] = customResult;
      data['custom_criteria_confidence'] = customConfidence ?? 0.0;
    }
    
    await FirebaseFirestore.instance.collection('images').add(data);
  }

  Future<void> _takePicture() async {
    try {
      final image = await _cameraController.takePicture();
      final savedImage = await _saveImage(image);
      
      // Classify the image for fruit ripeness using ML model
      await _classifyImage(savedImage);
      
      // Always detect color (no longer checking if enabled)
      await _detectColor(savedImage);
      
      // Apply custom criteria if enabled
      if (_useCustomCriteria) {
        await _applyCustomCriteria(savedImage);
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String imageUrl = await uploadImageToStorage(savedImage);
        await saveImageDetailsToFirestore(
          imageUrl, 
          widget.selectedFruit, 
          _result, 
          user.uid,
          detectedColor: _detectedColor, // Always save detected color
          customResult: _useCustomCriteria ? _customRipenessResult : null,
          customConfidence: _useCustomCriteria ? _criteriaConfidence : null,
        );

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetail(
              image: savedImage,
              result: _useCustomCriteria ? _customRipenessResult : _result,
              confidence: _useCustomCriteria ? [_criteriaConfidence, 0.0, 0.0] : _confidence,
              fruitName: widget.selectedFruit,
              detectedColor: _detectedColor, // Always pass detected color
              dominantColor: _dominantColor, // Always pass dominant color
              isCustomCriteria: _useCustomCriteria,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error taking picture: $e');
      }
    }
  }

 Future<void> _pickImageFromGallery() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);
    setState(() {
      _isProcessingImage = true;
    });

    await _processSelectedImage(imageFile);

    setState(() {
      _isProcessingImage = false;
    });

    if (!mounted) return;

    // Navigasi langsung ke ImageDetail
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetail(
          image: imageFile,
          result: _useCustomCriteria ? _customRipenessResult : _result,
          confidence: _useCustomCriteria ? [_criteriaConfidence, 0.0, 0.0] : _confidence,
          fruitName: widget.selectedFruit,
          detectedColor: _detectedColor,
          dominantColor: _dominantColor,
          isCustomCriteria: _useCustomCriteria,
        ),
      ),
    );
  }
}


Future<void> _processSelectedImage(File imageFile) async {
  try {
    await _classifyImage(imageFile);
    await _detectColor(imageFile);
    if (_useCustomCriteria) {
      await _applyCustomCriteria(imageFile);
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String imageUrl = await uploadImageToStorage(imageFile);
      await saveImageDetailsToFirestore(
        imageUrl,
        widget.selectedFruit,
        _result,
        user.uid,
        detectedColor: _detectedColor,
        customResult: _useCustomCriteria ? _customRipenessResult : null,
        customConfidence: _useCustomCriteria ? _criteriaConfidence : null,
      );
    }
  } catch (e) {
    if (kDebugMode) print('Error processing image: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


 Future<void> _classifyImage(File image) async {
  try {
    // First, resize the image to reduce processing load
    final originalImage = img.decodeImage(await image.readAsBytes());
    if (originalImage == null) return;
    
    // Create a smaller version for processing
    final resizedImage = img.copyResize(originalImage, 
      width: imageSize, 
      height: imageSize,
    );
    
    // Process the smaller image
    var inputBuffer = Float32List(1 * imageSize * imageSize * 3);
    var pixelIndex = 0;
    
    for (var y = 0; y < imageSize; y++) {
      for (var x = 0; x < imageSize; x++) {
        var pixel = resizedImage.getPixel(x, y);
        inputBuffer[pixelIndex++] = pixel.r / 255.0;
        inputBuffer[pixelIndex++] = pixel.g / 255.0;
        inputBuffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    var outputBuffer = List.filled(1 * 3, 0).reshape([1, 3]);
    _interpreter.run(inputBuffer.reshape([1, imageSize, imageSize, 3]), outputBuffer);
    
    var confidences = (outputBuffer[0] as List).map((v) => v as double).toList();
    var maxPos = confidences.indexOf(confidences.reduce((a, b) => a > b ? a : b));

    if (mounted) {
      setState(() {
        _result = _labels[maxPos];
        _confidence = confidences.map((conf) => conf * 100).toList();
      });
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error classifying image: $e');
    }
    if (mounted) {
      setState(() {
        _result = "Error";
        _confidence = [0, 0, 0];
      });
    }
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
         // 1. Camera preview - full screen background with better error handling
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && 
                _cameraController.value.isInitialized) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController.value.previewSize?.height ?? 0,
                    height: _cameraController.value.previewSize?.width ?? 0,
                    child: RotatedBox(
                      quarterTurns: -3,// atau 3
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white.withOpacity(0.5),
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Camera not available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can still select images from gallery',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),

       // Show processing overlay when selecting from gallery
        if (_isProcessingImage)
          Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Processing image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Frame border (capture area indicator)
        Center(
          child: Container(
            width: 280,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.orange,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // 4. Corner indicators for better frame visibility
        Center(
          child: Container(
            width: 280,
            height: 240,
            child: Stack(
              children: [
                // Top-left corner
                Positioned(
                
                  left: -2,
                  child: Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.orange, width: 4),
                        left: BorderSide(color: Colors.orange, width: 4),
                      ),
                    ),
                  ),
                ),
                // Top-right corner
                Positioned(
                  
                  right: -2,
                  child: Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.orange, width: 4),
                        right: BorderSide(color: Colors.orange, width: 4),
                      ),
                    ),
                  ),
                ),
                // Bottom-left corner
                Positioned(
                  
                  left: -2,
                  child: Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.orange, width: 4),
                        left: BorderSide(color: Colors.orange, width: 4),
                      ),
                    ),
                  ),
                ),
                // Bottom-right corner
                Positioned(
                 
                  right: -2,
                  child: Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.orange, width: 4),
                        right: BorderSide(color: Colors.orange, width: 4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Top controls bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                
                // Fruit name display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.selectedFruit,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                
                // Flash toggle
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isFlashOn 
                          ? Colors.orange.withOpacity(0.8)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // 6. Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom slider
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_currentZoomLevel.toStringAsFixed(1)}x',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _currentZoomLevel,
                      min: _minAvailableZoom,
                      max: _maxAvailableZoom,
                      activeColor: Colors.orange,
                      inactiveColor: Colors.white.withOpacity(0.3),
                      onChanged: (value) async {
                        setState(() {
                          _currentZoomLevel = value;
                        });
                        await _cameraController.setZoomLevel(value);
                      },
                    ),
                  ],
                ),
              ),
              
              // Camera controls
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Switch camera button
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onPressed: _switchCamera,
                    ),
                    
                    // Capture button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Settings button (for custom criteria toggle)
                    IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity((0.2)),
                      borderRadius: BorderRadius.circular(25)
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: _pickImageFromGallery,
                ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 7. Instructions text
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Position the ${widget.selectedFruit} within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}