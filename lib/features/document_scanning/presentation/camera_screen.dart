// features/document_scanning/presentation/camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/document_scanner.dart';
import '../../document_processing/presentation/document_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Start scanning automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanDocument();
    });
  }

  Future<void> _scanDocument() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final scanner = DocumentScanner();
      final imagePath = await scanner.scanDocument();

      if (imagePath != null && mounted) {
        final file = File(imagePath as String);
        final corners = await scanner.getDocumentCorners(imagePath as String);

        // Navigate to document preview screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DocumentPreviewScreen(imageFile: file, corners: corners),
          ),
        );
      } else if (mounted) {
        // User cancelled or error occurred, go back
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error scanning document: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning document: $e')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Document')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning) CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              _isScanning
                  ? 'Preparing scanner...'
                  : 'Touch the button below to scan',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            if (!_isScanning)
              ElevatedButton.icon(
                icon: Icon(Icons.document_scanner),
                label: Text('Scan Document'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _scanDocument,
              ),
          ],
        ),
      ),
    );
  }
}
