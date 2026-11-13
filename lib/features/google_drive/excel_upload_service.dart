import 'package:flutter/widgets.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/formatters.dart';
import '../../shared/period.dart';
import '../entries/entry_service.dart';
import '../users/user_service.dart';
import 'drive_client.dart';
import 'drive_service.dart';
import 'excel_builder.dart';

class ExcelResult {
  const ExcelResult({
    required this.ok,
    this.fileName,
    this.error,
    this.notConnected = false,
  });
  final bool ok;
  final String? fileName;
  final String? error;
  final bool notConnected;
}

/// Uploads Excel files of the entries to Google Drive: one every day (XLS-1,
/// XLS-2) and any time by hand for a chosen period (XLS-3, XLS-4). Every
/// upload is a new file; earlier files are never replaced (XLS-9).
class ExcelUploadService {
  ExcelUploadService({
    required this.drive,
    required this.entries,
    required this.users,
    required this.settings,
    this.now = DateTime.now,
  });
  final DriveService drive;
  final EntryService entries;
  final UserService users;
  final SettingsRepository settings;
  final DateTime Function() now;

  static const mime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// The language the app is set to (XLS-7).
  Future<AppLocalizations> _l10n() async {
    final lang = await settings.get(SettingKey.language);
    return AppLocalizations.delegate.load(Locale(lang == 'en' ? 'en' : 'bn'));
  }

  Future<DateTime?> lastDailyUpload() =>
      settings.getDateTime(SettingKey.lastExcelUploadAt);

  /// XLS-2: the daily upload is due when none has been made for today yet. A
  /// missed day (app closed at 12 AM, or no internet) is caught up as soon as
  /// the app is open and online, with one file named for today.
  Future<bool> isDailyDue() async =>
      (await settings.get(SettingKey.lastExcelDay)) != dayKey(now());

  /// XLS-1: every income and expense entry, all dates, no photos.
  Future<ExcelResult> uploadDaily() async {
    final l = await _l10n();
    final today = dayKey(now());
    final result = await _upload(
      l: l,
      period: Period(DateTime(2000), DateTime(2200)),
      content: ExcelContent.both,
      baseName: '${l.excelFilePrefix}_$today',
      description: l.logExcelDaily,
      kind: 'excel_daily',
    );
    if (result.ok) {
      await settings.set(SettingKey.lastExcelDay, today);
      await settings.setDateTime(SettingKey.lastExcelUploadAt, now());
      await settings.set(SettingKey.lastExcelError, '');
    } else if (!result.notConnected) {
      await settings.set(SettingKey.lastExcelError, result.error ?? '');
    }
    return result;
  }

  /// XLS-3 / XLS-4: a chosen period, income only, expense only or both.
  Future<ExcelResult> uploadManual({
    required Period period,
    required ExcelContent content,
    required String periodName,
  }) async {
    final l = await _l10n();
    final contentName = switch (content) {
      ExcelContent.income => l.pdfIncomeOnly,
      ExcelContent.expense => l.pdfExpenseOnly,
      ExcelContent.both => l.excelBoth,
    };
    return _upload(
      l: l,
      period: period,
      content: content,
      baseName:
          '${l.excelFilePrefix}_${dayKey(period.from)}_${dayKey(period.to)}_${content.name}',
      description: l.logExcelManual(periodName, contentName),
      kind: 'excel_manual',
    );
  }

  Future<ExcelResult> _upload({
    required AppLocalizations l,
    required Period period,
    required ExcelContent content,
    required String baseName,
    required String description,
    required String kind,
  }) async {
    final client = await drive.client();
    if (client == null) return const ExcelResult(ok: false, notConnected: true);
    try {
      final rows = await entries.inPeriod(
        period,
        type: switch (content) {
          ExcelContent.income => EntryType.income,
          ExcelContent.expense => EntryType.expense,
          ExcelContent.both => null,
        },
      );
      final names = {for (final u in await users.all()) u.id: u.name};
      final bytes = buildEntriesWorkbook(
        l: l,
        entries: rows,
        userNames: names,
        content: content,
      );
      final folder = await drive.folder(client, DriveFolders.excel);
      final name = await _freeName(client, folder, baseName);
      await client.upload(
        folderId: folder,
        name: name,
        bytes: bytes,
        mimeType: mime,
      );
      await drive.log(kind, description, ok: true);
      return ExcelResult(ok: true, fileName: name);
    } on DriveException catch (e) {
      await drive.log(kind, description, ok: false, error: e.message);
      return ExcelResult(ok: false, error: e.message);
    } catch (e) {
      await drive.log(kind, description, ok: false, error: '$e');
      return ExcelResult(ok: false, error: '$e');
    }
  }

  /// XLS-9: never replace an earlier file. If a file with this name is already
  /// in Drive, add the time to the name.
  Future<String> _freeName(
    DriveClient client,
    String folder,
    String base,
  ) async {
    final existing = (await client.list(folder)).map((f) => f.name).toSet();
    var name = '$base.xlsx';
    if (!existing.contains(name)) return name;
    final t = now();
    String two(int n) => n.toString().padLeft(2, '0');
    name = '${base}_${two(t.hour)}${two(t.minute)}${two(t.second)}.xlsx';
    var n = 2;
    while (existing.contains(name)) {
      name = '${base}_${two(t.hour)}${two(t.minute)}${two(t.second)}_$n.xlsx';
      n++;
    }
    return name;
  }
}
