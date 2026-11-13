import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'report_pdf_service.dart';
import 'save_pdf.dart';

/// "Export PDF" on the details screen: all of the entry's information and all
/// of its photos, in the app's language (DET-2, DET-3).
class EntryPdfButton extends StatefulWidget {
  const EntryPdfButton({super.key, required this.entry});
  final Entry entry;

  @override
  State<EntryPdfButton> createState() => _EntryPdfButtonState();
}

class _EntryPdfButtonState extends State<EntryPdfButton> {
  bool _busy = false;

  Future<void> _export() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final services = context.services;
    setState(() => _busy = true);
    try {
      final pdf = await services.reports.entryReport(
        l,
        fmt,
        widget.entry.id,
        thisDeviceId: services.deviceId,
      );
      if (!mounted) return;
      await savePdfWithDialog(context, pdf, entryFileName(widget.entry));
    } catch (e) {
      if (mounted) showError(context, l.pdfFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _busy ? null : _export,
    child: _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(context.l10n.pdfExport),
  );
}
