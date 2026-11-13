import 'dart:async';

import 'backup_service.dart';
import 'drive_service.dart';
import 'excel_upload_service.dart';

/// Runs the automatic Google Drive jobs while the app is open:
/// - a backup every 4 hours (BAK-2), at once on start if one is overdue
///   (BAK-4);
/// - the daily Excel upload, at 12 AM, or at once if a day was missed (XLS-1,
///   XLS-2);
/// - after a failure (for example no internet) it tries again every couple of
///   minutes until it works, which covers "when the connection comes back"
///   (BAK-3, XLS-2).
class DriveScheduler {
  DriveScheduler({
    required this.drive,
    required this.backup,
    required this.excel,
    this.now = DateTime.now,
    this.tick = const Duration(minutes: 1),
    this.retryAfter = const Duration(minutes: 2),
  });

  final DriveService drive;
  final BackupService backup;
  final ExcelUploadService excel;
  final DateTime Function() now;
  final Duration tick;
  final Duration retryAfter;

  Timer? _timer;
  DateTime? _backupFailedAt;
  DateTime? _excelFailedAt;
  bool _checking = false;

  /// Checks at once, then every [tick].
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => checkNow());
    checkNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool _cooledDown(DateTime? failedAt) =>
      failedAt == null || now().difference(failedAt) >= retryAfter;

  /// Runs whatever is due.
  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      if (await drive.client() == null) return; // no Google account connected
      if (!await backup.hasData())
        return; // nothing to protect yet (first launch)
      if (await backup.isDue() && _cooledDown(_backupFailedAt)) {
        final r = await backup.runBackup();
        _backupFailedAt = r.ok ? null : now();
      }
      if (await excel.isDailyDue() && _cooledDown(_excelFailedAt)) {
        final r = await excel.uploadDaily();
        _excelFailedAt = r.ok ? null : now();
      }
    } finally {
      _checking = false;
    }
  }

  /// BAK-8: a different Google account was connected: back up in full at once
  /// (photos are tracked per account, so they all go) and upload the Excel file.
  Future<void> onAccountChanged() async {
    if (!await backup.hasData()) return;
    await backup.runBackup(reason: 'new account');
    await excel.uploadDaily();
    _backupFailedAt = null;
    _excelFailedAt = null;
  }
}
