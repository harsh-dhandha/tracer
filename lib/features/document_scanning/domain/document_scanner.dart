// features/document_scanning/domain/document_scanner.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentScanner {
  final ImagePicker _picker = ImagePicker();

  // Use image_picker to capture or pick an image, and return its path
  Future<String?> scanDocument() async {
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      print('Camera permission not granted');
      return null;
    }

    try {
      // Pick image from camera
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile == null) {
        print('No image captured');
        return null;
      }

      // Optionally, move/copy the file to app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final targetPath = join(
        directory.path,
        "${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      final File imageFile = File(pickedFile.path);
      final File savedFile = await imageFile.copy(targetPath);

      return savedFile.path;
    } catch (e) {
      print('Error scanning document: $e');
      return null;
    }
  }

  Future<List<Offset>> getDocumentCorners(String imagePath) async {
    try {
      // Since we're no longer using edge_detection plugin for automatic corner detection,
      // you would implement a manual corner selection UI here.
      // You can present the image to the user with draggable corner points.

      // Return default corners (full image) for now
      return [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)];
    } catch (e) {
      print('Error getting document corners: $e');
      return [];
    }
  }
}
