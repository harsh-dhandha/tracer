// features/document_processing/domain/document_processor.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DocumentProcessor {
  // Apply perspective correction to the image
  Future<File> applyPerspectiveCorrection(
    File imageFile,
    List<Offset> corners,
  ) async {
    // The edge_detection plugin already handles perspective correction
    // so we can just return the original file
    return imageFile;
  }

  // Enhance image with filters
  Future<File> enhanceImage(
    File imageFile, {
    double brightness = 0.0,
    double contrast = 1.0,
    bool convertToGrayscale = false,
  }) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Process image
      img.Image processedImage = originalImage;

      // Apply grayscale if needed
      if (convertToGrayscale) {
        processedImage = img.grayscale(processedImage);
      }

      // Apply brightness and contrast
      processedImage = img.adjustColor(
        processedImage,
        brightness: brightness * 100, // Convert to percentage
        contrast: contrast,
      );

      // Create output file
      final tempDir = await getTemporaryDirectory();
      final enhancedFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_enhanced.jpg',
      );

      // Save enhanced image
      await enhancedFile.writeAsBytes(
        img.encodeJpg(processedImage, quality: 90),
      );

      return enhancedFile;
    } catch (e) {
      print('Error enhancing image: $e');
      return imageFile; // Return original if failed
    }
  }
}
