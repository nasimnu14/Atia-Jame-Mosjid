import '../database.dart';

/// Names of the single-value settings (plan Section 3).
abstract final class SettingKey {
  static const language = 'language'; // 'bn' | 'en'
  static const openingBalance = 'opening_balance'; // whole Taka
  static const openingBalanceDate = 'opening_balance_date'; // yyyy-MM-dd
  static const googleAccount = 'google_account';
  static const lastBackupAt = 'last_backup_at'; // ISO-8601
  static const lastBackupError = 'last_backup_error';
  static const lastExcelUploadAt = 'last_excel_upload_at';
  static const lastExcelDay =
      'last_excel_day'; // yyyy-MM-dd of last daily upload
  static const lastExcelError = 'last_excel_error';
  static const deviceId = 'device_id';
  static const deviceName = 'device_name';
  static const lastSyncAt = 'last_sync_at'; // phone: last successful sync
  static const lastUpdateCheckAt = 'last_update_check_at';
}

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) =>
      (_db.delete(_db.settings)..where((t) => t.key.equals(key))).go();

  Stream<String?> watch(String key) => (_db.select(
    _db.settings,
  )..where((t) => t.key.equals(key))).watchSingleOrNull().map((r) => r?.value);

  Future<int?> getInt(String key) async {
    final v = await get(key);
    return v == null ? null : int.tryParse(v);
  }

  Future<DateTime?> getDateTime(String key) async {
    final v = await get(key);
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> setDateTime(String key, DateTime value) =>
      set(key, value.toIso8601String());
}
