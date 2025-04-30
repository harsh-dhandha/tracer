// features/document_management/presentation/document_library_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/document_service.dart';
import '../../../shared/models/document_model.dart';
import './document_detail_screen.dart';

class DocumentLibraryScreen extends StatefulWidget {
  @override
  _DocumentLibraryScreenState createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final documentService = Provider.of<DocumentService>(
      context,
      listen: false,
    );
    await documentService.loadDocuments();
  }

  void _navigateToScan() {
    Navigator.pushNamed(context, '/scan');
  }

  void _openDocument(DocumentModel document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: document),
      ),
    );
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Document'),
                content: Text(
                  'Are you sure you want to delete "${document.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        final documentService = Provider.of<DocumentService>(
          context,
          listen: false,
        );
        await documentService.deleteDocument(document.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Documents'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Consumer<DocumentService>(
        builder: (context, documentService, child) {
          if (documentService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (documentService.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to scan your first document',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDocuments,
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: documentService.documents.length,
              itemBuilder: (context, index) {
                final document = documentService.documents[index];

                return GestureDetector(
                  onTap: () => _openDocument(document),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document thumbnail
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child:
                                document.thumbnailUrl != null
                                    ? Image.network(
                                      document.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (ctx, error, _) =>
                                              _localThumbnail(document),
                                    )
                                    : _localThumbnail(document),
                          ),
                        ),

                        // Document info
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteDocument(document),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScan,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _localThumbnail(DocumentModel document) {
    return FutureBuilder<bool>(
      future: File(document.thumbnailPath).exists(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Image.file(File(document.thumbnailPath), fit: BoxFit.cover);
        } else {
          return Icon(Icons.insert_drive_file, size: 50, color: Colors.grey);
        }
      },
    );
  }
}
