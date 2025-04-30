// features/document_management/presentation/document_builder_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/document_service.dart';
import '../domain/pdf_generator.dart';
import '../../../shared/models/document_model.dart';

class DocumentBuilderScreen extends StatefulWidget {
  final List<File> initialImages;

  DocumentBuilderScreen({required this.initialImages});

  @override
  _DocumentBuilderScreenState createState() => _DocumentBuilderScreenState();
}

class _DocumentBuilderScreenState extends State<DocumentBuilderScreen> {
  late List<File> _pages;
  final TextEditingController _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.initialImages);
    _titleController.text =
        'Document ${DateTime.now().toString().substring(0, 19)}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  void _removePage(int index) {
    setState(() {
      _pages.removeAt(index);
    });
  }

  void _addMorePages() async {
    // TODO: Implement camera or gallery picker
  }

  Future<void> _saveDocument() async {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot save empty document')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Show initial feedback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Creating document...')));

      final pdfGenerator = PdfGenerator();

      // Generate PDF
      final pdfFile = await pdfGenerator.generatePdf(
        title: _titleController.text,
        imageFiles: _pages,
      );

      // Verify file exists
      if (!await pdfFile.exists()) {
        throw Exception('PDF generation failed: File not found');
      }

      print('PDF generated at: ${pdfFile.path}');

      // Create the document model with a unique ID
      final String docId = DateTime.now().millisecondsSinceEpoch.toString();
      final document = DocumentModel(
        id: docId,
        title: _titleController.text,
        pageCount: _pages.length,
        createdAt: DateTime.now(),
        filePath: pdfFile.path,
        thumbnailPath: _pages.isNotEmpty ? _pages.first.path : '',
      );

      // Get document service
      final documentService = Provider.of<DocumentService>(
        context,
        listen: false,
      );

      // Save document locally
      await documentService.saveDocument(document);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Document saved successfully')));

        // Navigate back to home screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      print('Error in _saveDocument: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save document: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Document'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          // Document title input
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Page count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_pages.length} ${_pages.length == 1 ? 'page' : 'pages'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Page'),
                  onPressed: _addMorePages,
                ),
              ],
            ),
          ),

          // Pages list
          Expanded(
            child:
                _pages.isEmpty
                    ? Center(child: Text('No pages added yet'))
                    : ReorderableListView.builder(
                      itemCount: _pages.length,
                      onReorder: _reorderPages,
                      itemBuilder: (context, index) {
                        return Card(
                          key: ValueKey(_pages[index].path),
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Image.file(
                                _pages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text('Page ${index + 1}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePage(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Save button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDocument,
                  child:
                      _isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save Document'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
