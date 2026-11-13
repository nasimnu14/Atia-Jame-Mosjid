import 'package:flutter/material.dart';

import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'pdf/pdf_pages.dart';

/// Lets the user choose where to save a PDF (PDF-5) and says what happened.
Future<void> savePdfWithDialog(
  BuildContext context,
  RenderedPdf pdf,
  String fileName,
) async {
  final l = context.l10n;
  final saver = context.services.fileSaver;
  try {
    final path = await saver.save(
      context,
      suggestedName: fileName,
      bytes: pdf.bytes,
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
    if (!context.mounted) return;
    showInfo(context, path == null ? l.pdfNotSaved : l.pdfSaved(path));
  } catch (e) {
    if (context.mounted) showError(context, l.pdfFailed(e.toString()));
  }
}
