import 'dart:ui' as ui;

import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';
import '../../shared/role_text.dart';
import '../entries/entry_service.dart';
import '../users/user_service.dart';
import 'pdf/pdf_pages.dart';
import 'pdf/report_blocks.dart';

/// Makes the PDF files: period reports (PDF-1 to PDF-6) and a single entry
/// with its photos (DET-2, DET-3). The language is the one the app is in
/// (PDF-4).
class ReportPdfService {
  ReportPdfService(this._entries, this._users, this._now);
  final EntryService _entries;
  final UserService _users;
  final DateTime Function() _now;

  Future<RenderedPdf> periodReport(
    AppLocalizations l,
    Fmt fmt, {
    required Period period,
    required String periodName,
    required ReportContent content,
  }) async {
    final rows = await _entries.inPeriod(
      period,
      type: switch (content) {
        ReportContent.income => EntryType.income,
        ReportContent.expense => EntryType.expense,
        ReportContent.both => null,
      },
    );
    return renderPdf(
      buildPeriodReport(
        l: l,
        fmt: fmt,
        content: content,
        periodName: periodName,
        entries: rows,
      ),
      title: '${l.appName} — $periodName',
      footerLeft: l.pdfGeneratedOn(fmt.dateTime(_now())),
      pageLabel: (n, t) => l.pdfPageOf(fmt.integer(n), fmt.integer(t)),
    );
  }

  /// All the entry's information and all its photos (DET-2).
  Future<RenderedPdf> entryReport(
    AppLocalizations l,
    Fmt fmt,
    String entryId, {
    required String thisDeviceId,
    bool thisIsPhone = false,
  }) async {
    final data = await _entries.getWithPhotos(entryId);
    if (data == null) throw StateError('Entry not found');
    final e = data.entry;

    Future<String> who(String? id) async {
      final u = id == null ? null : await _users.byId(id);
      return u == null ? l.unknownUser : '${u.name} (${roleName(l, u.role)})';
    }

    // This device is the phone on the phone and the computer on the desktop.
    final madeOnPhone = (e.deviceId == thisDeviceId) == thisIsPhone;
    final device = madeOnPhone ? l.fromPhone : l.fromComputer;
    final history = EntryHistoryText(
      addedBy: l.addedBy(
        await _nameOnly(l, e.createdBy),
        await _roleOnly(l, e.createdBy),
        device,
        fmt.dateTime(e.createdAt),
      ),
      editedBy: e.editedAt == null
          ? null
          : l.pdfEditedByShort(
              await who(e.editedBy),
              fmt.dateTime(e.editedAt!),
            ),
      cancelledBy: e.cancelledAt == null
          ? null
          : l.pdfCancelledByShort(
              await who(e.cancelledBy),
              fmt.dateTime(e.cancelledAt!),
            ),
    );

    final images = <ui.Image>[];
    final photos = <PdfPhoto>[];
    try {
      for (final p in data.photos) {
        final bytes = await _entries.photoStorage.read(e.id, p.fileName);
        ui.Image? img;
        if (bytes != null) {
          try {
            final codec = await ui.instantiateImageCodec(bytes);
            img = (await codec.getNextFrame()).image;
            images.add(img);
          } catch (_) {
            img = null; // unreadable file: shown as missing
          }
        }
        photos.add(PdfPhoto(p.label, img));
      }
      return await renderPdf(
        buildEntryReport(
          l: l,
          fmt: fmt,
          entry: e,
          history: history,
          photos: photos,
        ),
        title: '${l.appName} — ${e.receiptNo}',
        footerLeft: l.pdfGeneratedOn(fmt.dateTime(_now())),
        pageLabel: (n, t) => l.pdfPageOf(fmt.integer(n), fmt.integer(t)),
      );
    } finally {
      for (final i in images) {
        i.dispose();
      }
    }
  }

  Future<String> _nameOnly(AppLocalizations l, String? id) async {
    final u = id == null ? null : await _users.byId(id);
    return u?.name ?? l.unknownUser;
  }

  Future<String> _roleOnly(AppLocalizations l, String? id) async {
    final u = id == null ? null : await _users.byId(id);
    return u == null ? '' : roleName(l, u.role);
  }
}

/// A file name that works on every system: `report-both-20261101-20261130`.
String reportFileName(ReportContent c, Period p) =>
    'report-${c.name}-${_ymd(p.from)}-${_ymd(p.to)}';

String entryFileName(Entry e) =>
    '${e.type.name}-${e.receiptNo}-${e.entryDate.replaceAll('-', '')}';

String _ymd(DateTime d) => dayKey(d).replaceAll('-', '');
