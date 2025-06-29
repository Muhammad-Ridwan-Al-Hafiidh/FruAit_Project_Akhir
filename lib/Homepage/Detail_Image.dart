import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ImageDetail extends StatelessWidget {
  final File image;
  final String result;
  final List<double> confidence;
  final String fruitName;
  final String? detectedColor;
  final Color? dominantColor;
  final bool isCustomCriteria;

  const ImageDetail({
    Key? key,
    required this.image,
    required this.result,
    required this.confidence,
    required this.fruitName,
    this.detectedColor,
    this.dominantColor,
    required this.isCustomCriteria,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$fruitName Analysis'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildAnalysisCard(context),
            const SizedBox(height: 16),
            _buildConfidenceCard(context),
            if (detectedColor != null && dominantColor != null)
              ...[_buildColorCard(context)],
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fruit Analysis',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Fruit: $fruitName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Ripeness: $result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getRipenessColor(result),
                  ),
                ),
              ],
            ),
            if (isCustomCriteria)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Result based on custom criteria',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard(BuildContext context) {
    List<String> labels = ["Matang", "Setengah Matang", "Belum Matang"];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence Scores',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
            ),
            const SizedBox(height: 12),
            ...List.generate(confidence.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(labels[index])),
                    Expanded(
                      flex: 5,
                      child: LinearProgressIndicator(
                        value: confidence[index] / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConfidenceColor(confidence[index]),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${confidence[index].toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color Analysis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dominantColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dominant Color: $detectedColor',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RGB: (${dominantColor!.red}, ${dominantColor!.green}, ${dominantColor!.blue})',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareResults(),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _shareResults() {
    String shareText = 'Fruit Analysis Results:\n'
        'Fruit: $fruitName\n'
        'Ripeness: $result\n';
    if (detectedColor != null) {
      shareText += 'Dominant Color: $detectedColor\n';
    }
    Share.share(shareText);
  }

  Color _getRipenessColor(String ripeness) {
    switch (ripeness) {
      case 'Matang':
        return Colors.green[600]!;
      case 'Setengah Matang':
        return Colors.orange[600]!;
      case 'Belum Matang':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 70) return Colors.green;
    if (confidence > 40) return Colors.orange;
    return Colors.red;
  }
}