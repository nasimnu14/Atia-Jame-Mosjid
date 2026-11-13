import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Phase 0 proof 1: does the `pdf` package join Bangla letters correctly?
/// Writes a PDF to $PROOF_OUT (default: build/proof_bangla.pdf).
void main() {
  test('write Bangla proof PDF', () async {
    final data = File('assets/fonts/HindSiliguri-Regular.ttf').readAsBytesSync();
    final font = pw.Font.ttf(data.buffer.asByteData());
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('যুক্তাক্ষর: ক্ষ ন্ত্র স্ত্রী ক্ষমতা বিদ্যালয় শ্রদ্ধা',
            style: pw.TextStyle(font: font, fontSize: 22)),
        pw.Text('আটিয়া জামে মসজিদ ১২৩৪৫৬৭৮৯০ ৳ ৫,০০০',
            style: pw.TextStyle(font: font, fontSize: 22)),
        pw.Text('কি কী কু কূ কে কৈ কো কৌ ক্র র‍্যাঙ্ক',
            style: pw.TextStyle(font: font, fontSize: 22)),
      ]),
    ));
    final out = File(Platform.environment['PROOF_OUT'] ?? 'build/proof_bangla.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(await doc.save());
    expect(out.existsSync(), isTrue);
  });
}
