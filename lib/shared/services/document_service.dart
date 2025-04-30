// shared/services/document_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../models/document_model.dart';

class DocumentService extends ChangeNotifier {
  // Keep Firebase references but don't use them for initial document operations
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<DocumentModel> _documents = [];
  bool _isLoading = false;

  // Key for storing documents in SharedPreferences
  static const String _localDocsKey = 'local_documents';

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;

  // Load local documents at startup
  DocumentService() {
    _loadLocalDocuments();
  }

  // Save document - completely local operation
  Future<void> saveDocument(DocumentModel document) async {
    try {
      _setLoading(true);

      // Add to in-memory list first
      _documents.add(document);

      // Immediately notify UI to update
      notifyListeners();

      // Save to SharedPreferences
      await _saveLocalDocuments();

      print('Document saved locally: ${document.title}');
    } catch (e) {
      print('Error saving document: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load documents from local storage only
  Future<void> loadDocuments() async {
    await _loadLocalDocuments();
  }

  // Private method to load documents from SharedPreferences
  Future<void> _loadLocalDocuments() async {
    try {
      _setLoading(true);

      final prefs = await SharedPreferences.getInstance();
      final String? docsJson = prefs.getString(_localDocsKey);

      if (docsJson != null && docsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(docsJson);

        // Convert JSON to DocumentModel objects
        final List<DocumentModel> loadedDocs =
            decodedList
                .map(
                  (json) =>
                      DocumentModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        // Filter out documents whose files no longer exist
        _documents = [];
        for (final doc in loadedDocs) {
          final pdfFile = File(doc.filePath);
          if (await pdfFile.exists()) {
            _documents.add(doc);
          } else {
            print(
              'Skipping document with missing file: ${doc.title} (${doc.filePath})',
            );
          }
        }

        // Sort by date descending (newest first)
        _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('Loaded ${_documents.length} documents from local storage');
      } else {
        print('No documents found in local storage');
      }

      notifyListeners();
    } catch (e) {
      print('Error loading local documents: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Save documents to SharedPreferences
  Future<void> _saveLocalDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert DocumentModel objects to JSON
      final List<Map<String, dynamic>> jsonList =
          _documents.map((doc) => doc.toJson()).toList();

      // Store JSON in SharedPreferences
      final String json = jsonEncode(jsonList);
      await prefs.setString(_localDocsKey, json);

      print('Saved ${jsonList.length} documents to local storage');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  // Delete document (local only)
  Future<void> deleteDocument(String documentId) async {
    try {
      _setLoading(true);

      // Find document index
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index < 0) {
        throw Exception('Document not found');
      }

      final document = _documents[index];

      // Delete local files
      try {
        // Delete PDF file
        final pdfFile = File(document.filePath);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
          print('Deleted PDF file: ${document.filePath}');
        }

        // Delete thumbnail if it exists and is different from original image
        final thumbnailFile = File(document.thumbnailPath);
        if (document.thumbnailPath != document.filePath &&
            await thumbnailFile.exists()) {
          await thumbnailFile.delete();
          print('Deleted thumbnail file: ${document.thumbnailPath}');
        }
      } catch (e) {
        print('Error deleting files: $e');
      }

      // Remove from in-memory list
      _documents.removeAt(index);

      // Update SharedPreferences
      await _saveLocalDocuments();

      // Update UI
      notifyListeners();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Upload to cloud - separate feature, not tied to initial document creation
  Future<void> uploadToCloud(String documentId) async {
    // Implementation for cloud upload (would be called separately)
    // Not implementing since we're focusing on local-first approach
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
