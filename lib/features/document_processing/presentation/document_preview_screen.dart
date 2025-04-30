// features/document_processing/presentation/document_preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/document_processor.dart';
import '../../document_management/presentation/document_builder_screen.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final File imageFile;
  final List<Offset> corners;

  DocumentPreviewScreen({required this.imageFile, required this.corners});

  @override
  _DocumentPreviewScreenState createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late File _processedImage;
  bool _isProcessing = true;
  String? _errorMessage;

  // Document processing options
  bool _isGrayscale = false;
  double _brightness = 0.0;
  double _contrast = 1.0;

  @override
  void initState() {
    super.initState();
    _processedImage =
        widget.imageFile; // Start with the already processed image
    _isProcessing = false; // No initial processing needed
  }

  Future<void> _applyFilters() async {
    setState(() => _isProcessing = true);

    try {
      final processor = DocumentProcessor();

      // Apply enhancement settings
      _processedImage = await processor.enhanceImage(
        widget.imageFile,
        brightness: _brightness,
        contrast: _contrast,
        convertToGrayscale: _isGrayscale,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      // Fallback to original image if processing fails
      _processedImage = widget.imageFile;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _updateFilters() {
    _applyFilters();
  }

  void _addToDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                DocumentBuilderScreen(initialImages: [_processedImage]),
      ),
    );
  }

  void _retakePhoto() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Document'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isProcessing ? null : _addToDocument,
          ),
        ],
      ),
      body:
          _isProcessing
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Image preview
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black12,
                      child:
                          _errorMessage != null
                              ? Center(
                                child: Text('Processing error: $_errorMessage'),
                              )
                              : Image.file(
                                _processedImage,
                                fit: BoxFit.contain,
                              ),
                    ),
                  ),

                  // Image adjustment controls
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adjustments',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),

                          // Grayscale toggle
                          Row(
                            children: [
                              Text('Grayscale'),
                              Spacer(),
                              Switch(
                                value: _isGrayscale,
                                onChanged: (value) {
                                  setState(() => _isGrayscale = value);
                                  _updateFilters();
                                },
                              ),
                            ],
                          ),

                          // Brightness slider
                          Text('Brightness'),
                          Slider(
                            value: _brightness,
                            min: -1.0,
                            max: 1.0,
                            divisions: 20,
                            label: _brightness.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() => _brightness = value);
                            },
                            onChangeEnd: (_) => _updateFilters(),
                          ),

                          // Contrast slider
                          Text('Contrast'),
                          Slider(
                            value: _contrast,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: _contrast.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() => _contrast = value);
                            },
                            onChangeEnd: (_) => _updateFilters(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retakePhoto,
                            child: Text('Retake'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _addToDocument,
                            child: Text('Use This Image'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
