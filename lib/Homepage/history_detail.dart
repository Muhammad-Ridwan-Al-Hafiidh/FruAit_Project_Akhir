import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class DetailPage extends StatefulWidget {
  final String imageUrl;
  final String fruitName;
  final String result;
  final String color;
  final DateTime timestamp;

  const DetailPage({
    Key? key,
    required this.imageUrl,
    required this.fruitName,
    required this.result,
    required this.color,
    required this.timestamp,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Timer? _timer;
  Duration? _timeToRipe;
  Duration? _timeToSpoil;
  
  @override
  void initState() {
    super.initState();
    _calculateCountdowns();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateCountdowns() {
    final now = DateTime.now();
    
    // Estimasi waktu berdasarkan status kematangan
    switch (widget.result.toLowerCase()) {
      case 'belum matang':
        // Belum matang: 3-5 hari untuk matang, 7-10 hari untuk busuk
        final ripeTime = widget.timestamp.add(Duration(days: 4));
        final spoilTime = widget.timestamp.add(Duration(days: 8));
        
        _timeToRipe = ripeTime.isAfter(now) ? ripeTime.difference(now) : null;
        _timeToSpoil = spoilTime.isAfter(now) ? spoilTime.difference(now) : null;
        break;
        
      case 'setengah matang':
        // Setengah matang: 1-2 hari untuk matang, 4-6 hari untuk busuk
        final ripeTime = widget.timestamp.add(Duration(days: 2));
        final spoilTime = widget.timestamp.add(Duration(days: 5));
        
        _timeToRipe = ripeTime.isAfter(now) ? ripeTime.difference(now) : null;
        _timeToSpoil = spoilTime.isAfter(now) ? spoilTime.difference(now) : null;
        break;
        
      case 'matang':
        // Sudah matang: langsung siap konsumsi, 2-4 hari untuk busuk
        final spoilTime = widget.timestamp.add(Duration(days: 3));
        
        _timeToRipe = null; // Sudah matang
        _timeToSpoil = spoilTime.isAfter(now) ? spoilTime.difference(now) : null;
        break;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _calculateCountdowns();
      });
    });
  }

  Color _getStatusColor() {
    switch (widget.result.toLowerCase()) {
      case 'matang':
        return Colors.green;
      case 'setengah matang':
        return Colors.orange;
      case 'belum matang':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      final minutes = duration.inMinutes % 60;
      return '${days}h ${hours}j ${minutes}m';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      return '${hours}j ${minutes}m ${seconds}d';
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}m ${seconds}d';
    }
  }

  Widget _buildCountdownCard({
    required String title,
    required Duration? duration,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              duration != null 
                ? _formatDuration(duration)
                : (title.contains('Matang') ? 'Sudah Matang!' : 'Sudah Busuk!'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: duration != null ? Colors.black87 : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRecommendation() {
    String recommendation;
    Color recommendationColor;
    IconData recommendationIcon;

    switch (widget.result.toLowerCase()) {
      case 'belum matang':
        recommendation = 'Simpan di tempat sejuk dan kering. Buah akan matang dalam beberapa hari.';
        recommendationColor = Colors.blue;
        recommendationIcon = Icons.access_time;
        break;
      case 'setengah matang':
        recommendation = 'Buah hampir siap dikonsumsi. Pantau perkembangannya setiap hari.';
        recommendationColor = Colors.orange;
        recommendationIcon = Icons.visibility;
        break;
      case 'matang':
        recommendation = 'Buah siap dikonsumsi! Segera konsumsi sebelum busuk.';
        recommendationColor = Colors.green;
        recommendationIcon = Icons.restaurant;
        break;
      default:
        recommendation = 'Status tidak dikenal';
        recommendationColor = Colors.grey;
        recommendationIcon = Icons.help;
    }

    return Card(
      color: recommendationColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              recommendationIcon,
              color: recommendationColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendation,
                style: TextStyle(
                  fontSize: 14,
                  color: recommendationColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail ${widget.fruitName}'),
        backgroundColor: _getStatusColor(),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar buah
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.error, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Detail informasi
            _buildDetailRow('Buah', widget.fruitName),
            Divider(),
            _buildDetailRow('Status', widget.result, color: _getStatusColor()),
            Divider(),
            _buildDetailRow('Warna', widget.color),
            Divider(),
            _buildDetailRow(
              'Tanggal Deteksi',
              DateFormat('dd MMMM yyyy - HH:mm').format(widget.timestamp),
            ),
            
            SizedBox(height: 24),
            
            // Countdown section
            Text(
              'Perkiraan Waktu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                if (_timeToRipe != null)
                  Expanded(
                    child: _buildCountdownCard(
                      title: 'Waktu untuk\nMatang',
                      duration: _timeToRipe,
                      color: Colors.green,
                      icon: Icons.schedule,
                    ),
                  ),
                if (_timeToRipe != null && _timeToSpoil != null)
                  SizedBox(width: 8),
                if (_timeToSpoil != null)
                  Expanded(
                    child: _buildCountdownCard(
                      title: 'Waktu untuk\nBusuk',
                      duration: _timeToSpoil,
                      color: Colors.red,
                      icon: Icons.warning,
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Rekomendasi
            Text(
              'Rekomendasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildStatusRecommendation(),
            
            SizedBox(height: 16),
            
            // Catatan
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan: Waktu ini adalah perkiraan dan dapat bervariasi tergantung kondisi penyimpanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
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
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.black,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}