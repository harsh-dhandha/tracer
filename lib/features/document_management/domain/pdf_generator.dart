// features/document_management/domain/pdf_generator.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  Future<File> generatePdf({
    required String title,
    required List<File> imageFiles,
  }) async {
    final pdf = pw.Document();

    // Add document metadata
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> widgets = [];

          // Add title page
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          // Add creation date
          widgets.add(
            pw.Text(
              'Created on: ${DateTime.now().toString().substring(0, 10)}',
              style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));
          widgets.add(pw.Divider());

          // Add all pages
          for (var i = 0; i < imageFiles.length; i++) {
            final imageFile = imageFiles[i];
            final imageBytes = imageFile.readAsBytesSync();

            widgets.add(
              pw.Container(
                alignment: pw.Alignment.center,
                margin: pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.contain,
                  width: 500,
                ),
              ),
            );

            // Add page number
            widgets.add(
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Page ${i + 1} of ${imageFiles.length}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            );

            // Add page break if not the last page
            if (i < imageFiles.length - 1) {
              widgets.add(pw.NewPage());
            }
          }

          return widgets;
        },
      ),
    );

    // Save the PDF
    final output = await getApplicationDocumentsDirectory();
    final String sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filePath =
        '${output.path}/${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    try {
      // Make sure directory exists
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      // Save the file
      await file.writeAsBytes(await pdf.save());

      // Verify the file was created
      if (!await file.exists()) {
        throw Exception('Failed to write PDF file');
      }

      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }
}
