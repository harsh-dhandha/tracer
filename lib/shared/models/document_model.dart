// shared/models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String title;
  final int pageCount;
  final DateTime createdAt;
  final String filePath;
  final String thumbnailPath;
  final String? pdfUrl;
  final String? thumbnailUrl;

  DocumentModel({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.createdAt,
    required this.filePath,
    required this.thumbnailPath,
    this.pdfUrl,
    this.thumbnailUrl,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      pageCount: data['pageCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      filePath: data['localFilePath'] ?? '',
      thumbnailPath: data['localThumbnailPath'] ?? '',
      pdfUrl: data['pdfUrl'],
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  // Add methods for serialization to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pageCount': pageCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'pdfUrl': pdfUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      pageCount: json['pageCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      filePath: json['filePath'] ?? '',
      thumbnailPath: json['thumbnailPath'] ?? '',
      pdfUrl: json['pdfUrl'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }
}
