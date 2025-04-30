import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ShareService {
  static const platform = MethodChannel('app.tracer/share');

  /// Shares files with given title and text
  static Future<void> shareFiles(
    List<String> filePaths, {
    String? text,
    String? subject,
  }) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use method channel for native sharing
        await platform.invokeMethod('shareFiles', {
          'filePaths': filePaths,
          'text': text ?? '',
          'subject': subject ?? '',
        });
      } else {
        // Fallback for other platforms - could implement web or desktop sharing
        print('Sharing not implemented for this platform');
      }
    } on PlatformException catch (e) {
      print("Failed to share files: ${e.message}");
    }
  }

  /// Shares text content
  static Future<void> share(String text, {String? subject}) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use method channel for native sharing
        await platform.invokeMethod('shareText', {
          'text': text,
          'subject': subject ?? '',
        });
      } else {
        // Fallback for other platforms
        print('Sharing not implemented for this platform');
      }
    } on PlatformException catch (e) {
      print("Failed to share text: ${e.message}");
    }
  }
}
