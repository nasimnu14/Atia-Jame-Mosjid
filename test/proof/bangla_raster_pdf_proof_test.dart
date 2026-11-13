import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Phase 0 proof 1 (fallback): draw the page with Flutter's text engine
/// (correct Bangla shaping), then embed it as an image in the PDF.
void main() {
  testWidgets('rasterised Bangla PDF', (tester) async {
    final bytes = await tester.runAsync(() async {
      final loader = FontLoader('HindSiliguri')
        ..addFont(Future.value(
            File('assets/fonts/HindSiliguri-Regular.ttf').readAsBytesSync().buffer.asByteData()));
      await loader.load();
      const w = 1240.0, h = 1754.0; // A4 at 150 dpi
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
      var y = 60.0;
      for (final line in const [
        'যুক্তাক্ষর: ক্ষ ন্ত্র স্ত্রী ক্ষমতা বিদ্যালয় শ্রদ্ধা',
        'আটিয়া জামে মসজিদ ১২৩৪৫৬৭৮৯০ ৳ ৫,০০০',
        'কি কী কু কূ কে কৈ কো কৌ ক্র র‍্যাঙ্ক',
      ]) {
        final tp = TextPainter(
          text: TextSpan(
              text: line,
              style: const TextStyle(
                  fontFamily: 'HindSiliguri', fontSize: 44, color: Colors.black)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w - 120);
        tp.paint(canvas, Offset(60, y));
        y += tp.height + 20;
      }
      final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      final png = data!.buffer.asUint8List();
      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(Uint8List.fromList(png)), fit: pw.BoxFit.fill),
      ));
      return doc.save();
    });
    final out = File(Platform.environment['PROOF_OUT'] ?? 'build/proof_raster.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!);
    expect(bytes.length, greaterThan(1000));
  });
}
