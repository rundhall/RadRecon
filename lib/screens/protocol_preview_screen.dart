import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// A kész jegyzőkönyv PDF-előnézete megosztás előtt. A megosztás az AppBar
/// gombjával történik, ugyanúgy, mint a DOCX-export esetén.
class ProtocolPreviewScreen extends StatelessWidget {
  const ProtocolPreviewScreen({
    super.key,
    required this.file,
    required this.title,
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(file.path)], subject: title),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => file.readAsBytes(),
        pdfFileName: file.uri.pathSegments.last,
        allowSharing: false,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
