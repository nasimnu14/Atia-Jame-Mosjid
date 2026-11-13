import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/theme.dart';

/// Why pages are drawn here instead of with the `pdf` package's own text:
/// that package does not join Bangla letters correctly (phase 0 proof).
/// Flutter's text engine does, so each page is painted with it and embedded
/// as an image. Cost: the text in the PDF cannot be selected or searched.
abstract final class PageSpec {
  /// A4 in points.
  static const width = 595.28;
  static const height = 841.89;
  static const margin = 42.0;
  static const contentWidth = width - margin * 2;
  static const footerHeight = 26.0;
  static const contentHeight = height - margin - margin - footerHeight;

  /// Pixels per point when the page is drawn (2.5 is about 180 dpi).
  static const scale = 2.5;
}

const _ink = Color(0xFF1C2B26);
const _hair = Color(0xFFD5DCD8);

TextStyle pdfStyle({
  double size = 10,
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
  TextDecoration? decoration,
  double height = 1.35,
}) => TextStyle(
  fontFamily: kFontFamily,
  fontSize: size,
  fontWeight: weight,
  color: color,
  decoration: decoration,
  height: height,
);

/// One piece of a page. Blocks are laid out top to bottom and split across
/// pages between blocks, never inside one.
abstract class PdfBlock {
  double get height;

  /// The words in this block, for tests.
  String get debugText;
  void paint(Canvas canvas, Offset origin);

  /// A heading: stay on the same page as the block after it.
  bool get keepWithNext => false;

  /// A table's header row, repeated at the top of each page the table
  /// continues on.
  bool get isTableHeader => false;
  bool get isTableRow => false;
}

class SpacerBlock extends PdfBlock {
  SpacerBlock(this.height);
  @override
  final double height;
  @override
  String get debugText => '';
  @override
  void paint(Canvas canvas, Offset origin) {}
}

class TextBlock extends PdfBlock {
  TextBlock(
    this.text, {
    TextStyle? style,
    TextAlign align = TextAlign.left,
    this.padding = const EdgeInsets.symmetric(vertical: 1),
    this.keepWithNext = false,
    this.bottomRule = false,
    this.background,
  }) {
    _tp =
        TextPainter(
          text: TextSpan(text: text, style: style ?? pdfStyle()),
          textAlign: align,
          textDirection: TextDirection.ltr,
        )..layout(
          minWidth: PageSpec.contentWidth - padding.horizontal,
          maxWidth: PageSpec.contentWidth - padding.horizontal,
        );
  }
  late final TextPainter _tp;
  final String text;
  final EdgeInsets padding;
  final bool bottomRule;
  final Color? background;
  @override
  final bool keepWithNext;

  @override
  String get debugText => text;

  @override
  double get height => _tp.height + padding.vertical;

  @override
  void paint(Canvas canvas, Offset origin) {
    if (background != null) {
      canvas.drawRect(
        Rect.fromLTWH(origin.dx, origin.dy, PageSpec.contentWidth, height),
        Paint()..color = background!,
      );
    }
    _tp.paint(canvas, origin + Offset(padding.left, padding.top));
    if (bottomRule) {
      canvas.drawLine(
        origin + Offset(0, height),
        origin + Offset(PageSpec.contentWidth, height),
        Paint()
          ..color = _ink
          ..strokeWidth = 0.8,
      );
    }
  }
}

/// A column: fixed width in points, or a share of what is left.
class PdfCol {
  const PdfCol.fixed(this.size) : flex = false;
  const PdfCol.flex(this.size) : flex = true;
  final double size;
  final bool flex;
}

class PdfCell {
  const PdfCell(this.text, {this.align = TextAlign.left, this.style});
  final String text;
  final TextAlign align;
  final TextStyle? style;
}

/// A table row (or header, or total row).
class RowBlock extends PdfBlock {
  RowBlock(
    List<PdfCol> cols,
    List<PdfCell> cells, {
    this.header = false,
    this.background,
    this.topRule = false,
    this.rowLine = true,
    TextStyle? baseStyle,
  }) : _cols = cols,
       debugText = cells.map((c) => c.text).join(' | ') {
    assert(cols.length == cells.length);
    final fixed = cols
        .where((c) => !c.flex)
        .fold<double>(0, (a, c) => a + c.size);
    final flexTotal = cols
        .where((c) => c.flex)
        .fold<double>(0, (a, c) => a + c.size);
    final gaps = (cols.length - 1) * _gap;
    final free = PageSpec.contentWidth - fixed - gaps - _pad * 2;
    var x = _pad;
    var tallest = 0.0;
    for (var i = 0; i < cols.length; i++) {
      final w = cols[i].flex ? free * cols[i].size / flexTotal : cols[i].size;
      final tp = TextPainter(
        text: TextSpan(
          text: cells[i].text,
          style:
              cells[i].style ??
              baseStyle ??
              pdfStyle(
                size: header ? 9 : 10,
                weight: header ? FontWeight.w700 : FontWeight.w400,
                color: header ? const Color(0xFF3D4C46) : _ink,
              ),
        ),
        textAlign: cells[i].align,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: w, maxWidth: w);
      _painters.add(tp);
      _xs.add(x);
      x += w + _gap;
      if (tp.height > tallest) tallest = tp.height;
    }
    height = tallest + _vPad * 2;
  }

  static const _gap = 6.0;
  static const _pad = 4.0;
  static const _vPad = 3.0;
  final List<PdfCol> _cols;
  @override
  final String debugText;
  final _painters = <TextPainter>[];
  final _xs = <double>[];
  final bool header;
  final Color? background;
  final bool topRule;
  final bool rowLine;

  @override
  late final double height;

  @override
  bool get isTableHeader => header;
  @override
  bool get isTableRow => !header && _cols.isNotEmpty;

  @override
  void paint(Canvas canvas, Offset origin) {
    if (header || background != null) {
      canvas.drawRect(
        Rect.fromLTWH(origin.dx, origin.dy, PageSpec.contentWidth, height),
        Paint()..color = background ?? const Color(0xFFEEF2F0),
      );
    }
    for (var i = 0; i < _painters.length; i++) {
      _painters[i].paint(canvas, origin + Offset(_xs[i], _vPad));
    }
    if (topRule) {
      canvas.drawLine(
        origin,
        origin + Offset(PageSpec.contentWidth, 0),
        Paint()
          ..color = _ink
          ..strokeWidth = 0.9,
      );
    }
    if (rowLine) {
      canvas.drawLine(
        origin + Offset(0, height),
        origin + Offset(PageSpec.contentWidth, height),
        Paint()
          ..color = _hair
          ..strokeWidth = 0.5,
      );
    }
  }
}

/// A photo with its label under it.
class ImageBlock extends PdfBlock {
  ImageBlock(this.image, String label, {double maxHeight = 300}) {
    final maxW = PageSpec.contentWidth * 0.92;
    final scale = [
      maxW / image.width,
      maxHeight / image.height,
      1.0 * 4,
    ].reduce((a, b) => a < b ? a : b);
    _w = image.width * scale;
    _h = image.height * scale;
    _label = TextPainter(
      text: TextSpan(
        text: label,
        style: pdfStyle(size: 10, color: const Color(0xFF3D4C46)),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: PageSpec.contentWidth);
  }
  final ui.Image image;
  @override
  String get debugText => _label.text?.toPlainText() ?? '';
  late final double _w, _h;
  late final TextPainter _label;

  @override
  double get height => _h + _label.height + 12;

  @override
  void paint(Canvas canvas, Offset origin) {
    final rect = Rect.fromLTWH(origin.dx, origin.dy + 2, _w, _h);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _hair
        ..strokeWidth = 0.6,
    );
    _label.paint(canvas, Offset(origin.dx, origin.dy + _h + 6));
  }
}

/// Splits [blocks] into pages: a block never splits; a heading stays with the
/// block after it; a table's header row is repeated on the next page.
List<List<PdfBlock>> paginate(List<PdfBlock> blocks) {
  final pages = <List<PdfBlock>>[[]];
  var used = 0.0;
  PdfBlock? header;
  void newPage() {
    pages.add([]);
    used = 0;
  }

  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    var need = b.height;
    if (b.keepWithNext && i + 1 < blocks.length) need += blocks[i + 1].height;
    if (b.isTableHeader && i + 1 < blocks.length) need += blocks[i + 1].height;
    final empty = pages.last.isEmpty;
    if (!empty && used + need > PageSpec.contentHeight) {
      newPage();
      // Continue a table: repeat its header.
      if (b.isTableRow && header != null) {
        pages.last.add(header);
        used += header.height;
      }
    }
    if (b.isTableHeader) header = b;
    if (!b.isTableRow && !b.isTableHeader) header = null;
    pages.last.add(b);
    used += b.height;
  }
  return pages;
}

/// Draws one page to a PNG.
Future<Uint8List> paintPage(
  List<PdfBlock> page, {
  required String footerLeft,
  required String footerRight,
}) async {
  const s = PageSpec.scale;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec)..scale(s);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, PageSpec.width, PageSpec.height),
    Paint()..color = Colors.white,
  );
  var y = PageSpec.margin;
  for (final b in page) {
    b.paint(canvas, Offset(PageSpec.margin, y));
    y += b.height;
  }
  final footerY = PageSpec.height - PageSpec.margin - 12;
  canvas.drawLine(
    Offset(PageSpec.margin, footerY - 4),
    Offset(PageSpec.width - PageSpec.margin, footerY - 4),
    Paint()
      ..color = _hair
      ..strokeWidth = 0.5,
  );
  void foot(String text, bool right) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: pdfStyle(size: 8, color: const Color(0xFF5B6B65)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        right ? PageSpec.width - PageSpec.margin - tp.width : PageSpec.margin,
        footerY,
      ),
    );
  }

  foot(footerLeft, false);
  foot(footerRight, true);
  final image = await rec.endRecording().toImage(
    (PageSpec.width * s).round(),
    (PageSpec.height * s).round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

class RenderedPdf {
  const RenderedPdf(this.bytes, this.pagePngs);

  /// The finished PDF file.
  final Uint8List bytes;

  /// Each page as a PNG (the first is used as the on-screen preview).
  final List<Uint8List> pagePngs;
  int get pageCount => pagePngs.length;
}

/// Paginates, paints and assembles the PDF. [pageLabel] gives the footer text
/// for page n of total.
Future<RenderedPdf> renderPdf(
  List<PdfBlock> blocks, {
  required String footerLeft,
  required String Function(int n, int total) pageLabel,
  String title = '',
}) async {
  final pages = paginate(blocks);
  final pngs = <Uint8List>[];
  for (var i = 0; i < pages.length; i++) {
    pngs.add(
      await paintPage(
        pages[i],
        footerLeft: footerLeft,
        footerRight: pageLabel(i + 1, pages.length),
      ),
    );
  }
  final doc = pw.Document(title: title, creator: 'Atia Jame Masjid');
  for (final png in pngs) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.fill),
      ),
    );
  }
  return RenderedPdf(await doc.save(), pngs);
}
