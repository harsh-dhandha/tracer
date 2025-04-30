// features/home/presentation/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/document_service.dart';
import '../../../shared/models/document_model.dart';
import '../../document_scanning/presentation/camera_screen.dart';
import '../../document_management/presentation/document_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen()));
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

  void _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracer'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              } else if (value == 'settings') {
                // TODO: Navigate to settings
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Documents tab
          _buildDocumentsTab(),

          // Recent tab
          _buildRecentTab(),

          // Profile tab
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScan,
        child: Icon(Icons.document_scanner),
        tooltip: 'Scan Document',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Recent',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Consumer<DocumentService>(
      builder: (context, documentService, child) {
        if (documentService.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (documentService.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No documents yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the scan button to scan your first document',
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
                          child: _buildThumbnail(document),
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
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
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
    );
  }

  Widget _buildRecentTab() {
    return Consumer<DocumentService>(
      builder: (context, documentService, child) {
        // Show loading indicator when service is loading
        if (documentService.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Show empty state when no documents
        if (documentService.documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No documents yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the scan button to create your first document',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Get list of documents (already sorted in DocumentService)
        final recentDocs = documentService.documents.take(5).toList();

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: recentDocs.length,
          itemBuilder: (context, index) {
            final document = recentDocs[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: _buildThumbnail(document),
                title: Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _formatDate(document.createdAt),
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.open_in_new, size: 20),
                      onPressed: () => _openDocument(document),
                    ),
                  ],
                ),
                onTap: () => _openDocument(document),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName![0].toUpperCase()
                  : (user?.email?[0].toUpperCase() ?? '?'),
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(user?.email ?? '', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 32),
          _buildProfileButton(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          _buildProfileButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          _buildProfileButton(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          _buildProfileButton(
            icon: Icons.logout,
            label: 'Logout',
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildThumbnail(DocumentModel document) {
    // First try to load local thumbnail
    final file = File(document.thumbnailPath);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 56,
            height: 56,
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.data == true) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(file, fit: BoxFit.cover),
            ),
          );
        } else {
          // Fallback icon if thumbnail doesn't exist
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.insert_drive_file, color: Colors.grey),
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
