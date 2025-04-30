import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:tracer/shared/services/document_service.dart';

class CornerEditorScreen extends StatefulWidget {
  final File imageFile;

  const CornerEditorScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  _CornerEditorScreenState createState() => _CornerEditorScreenState();
}

class _CornerEditorScreenState extends State<CornerEditorScreen> {
  late List<Offset> corners;
  late Size imageSize;

  @override
  void initState() {
    super.initState();
    // Initialize corners to default positions (corners of the image)
    imageSize = Size(300, 400); // Will be updated when image loads
    _initializeCorners();
  }

  void _initializeCorners() {
    corners = [
      Offset(0, 0), // Top-left
      Offset(imageSize.width, 0), // Top-right
      Offset(imageSize.width, imageSize.height), // Bottom-right
      Offset(0, imageSize.height), // Bottom-left
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adjust Corners')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Size>(
              future: _getImageSize(widget.imageFile),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                imageSize = snapshot.data!;
                if (corners.isEmpty) {
                  _initializeCorners();
                }

                return Stack(
                  children: [
                    // Display the image
                    Center(child: Image.file(widget.imageFile)),
                    // Place draggable corner points
                    ...corners.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Offset point = entry.value;
                      return Positioned(
                        left: point.dx - 12,
                        top: point.dy - 12,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              corners[idx] += details.delta;
                              // Keep points within image bounds
                              corners[idx] = Offset(
                                corners[idx].dx.clamp(0, imageSize.width),
                                corners[idx].dy.clamp(0, imageSize.height),
                              );
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    // Draw lines between corners
                    CustomPaint(
                      size: Size.infinite,
                      painter: CornersPainter(corners),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _processImage(context),
              child: Text('Crop & Continue'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final decodedImage = await decodeImageFromList(
      await imageFile.readAsBytes(),
    );
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  void _processImage(BuildContext context) async {
    // Here you would implement image cropping based on the selected corners
    // This is a placeholder - you'll need to implement the actual perspective transform

    // For example:
    // final croppedImage = await _perspectiveTransform(widget.imageFile, corners);

    // Then navigate to the next screen with the cropped image
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => NextScreen(imageFile: croppedFile),
    //   ),
    // );
  }
}

class CornersPainter extends CustomPainter {
  final List<Offset> corners;

  CornersPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    if (corners.length == 4) {
      final path =
          Path()
            ..moveTo(corners[0].dx, corners[0].dy)
            ..lineTo(corners[1].dx, corners[1].dy)
            ..lineTo(corners[2].dx, corners[2].dy)
            ..lineTo(corners[3].dx, corners[3].dy)
            ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
