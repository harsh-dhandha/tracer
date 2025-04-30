// features/document_management/presentation/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../../shared/models/document_model.dart';
import 'package:tracer/shared/services/share_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  DocumentDetailScreen({required this.document});

  @override
  _DocumentDetailScreenState createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sharePdf() async {
    try {
      setState(() => _isLoading = true);

      // Check if local file exists
      final file = File(widget.document.filePath);
      if (await file.exists()) {
        await ShareService.shareFiles([
          widget.document.filePath,
        ], text: 'Sharing ${widget.document.title}');
      } else if (widget.document.pdfUrl != null) {
        // If local file doesn't exist but we have a URL
        await ShareService.share(
          'View my document: ${widget.document.pdfUrl}',
          subject: widget.document.title,
        );
      } else {
        throw Exception('PDF file not available for sharing');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printPdf() async {
    try {
      setState(() => _isLoading = true);

      final file = File(widget.document.filePath);
      if (await file.exists()) {
        await Printing.layoutPdf(
          onLayout: (_) => file.readAsBytes(),
          name: widget.document.title,
        );
      } else {
        throw Exception('PDF file not available for printing');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _isLoading ? null : _sharePdf,
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _isLoading ? null : _printPdf,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Document information header
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Document thumbnail
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildThumbnail(),
                        ),
                        SizedBox(width: 16),

                        // Document details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.document.title,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Created on: ${_formatDate(widget.document.createdAt)}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${widget.document.pageCount} ${widget.document.pageCount == 1 ? 'page' : 'pages'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(),

                  // PDF Viewer
                  Expanded(child: _buildPdfViewer()),

                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.red[50],
                      width: double.infinity,
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildThumbnail() {
    // First try local thumbnail
    if (widget.document.thumbnailPath.isNotEmpty) {
      final file = File(widget.document.thumbnailPath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(file, fit: BoxFit.cover);
          } else {
            // If local thumbnail doesn't exist, try remote URL
            if (widget.document.thumbnailUrl != null) {
              return Image.network(
                widget.document.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        Icon(Icons.insert_drive_file, color: Colors.grey),
              );
            } else {
              return Icon(Icons.insert_drive_file, color: Colors.grey);
            }
          }
        },
      );
    } else if (widget.document.thumbnailUrl != null) {
      // If no local path but we have a URL
      return Image.network(
        widget.document.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Icon(Icons.insert_drive_file, color: Colors.grey),
      );
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  Widget _buildPdfViewer() {
    final file = File(widget.document.filePath);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          // Local file exists, show PDF preview
          return PdfPreview(
            build: (format) => file.readAsBytes(),
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: false,
            allowSharing: false,
            maxPageWidth: 700,
          );
        } else {
          // PDF not available
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  'PDF file not found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'The file may have been moved or deleted',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
