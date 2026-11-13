import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Entries,
    Photos,
    Approvers,
    Settings,
    SyncLog,
    DriveUploadedPhotos,
    DriveLog,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Bump this and add a step to [migration] whenever a table changes.
  /// Add a test in test/data/migration_test.dart for every step.
  static const currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX idx_entries_type_receipt ON entries (type, receipt_no)',
      );
      await customStatement(
        'CREATE INDEX idx_entries_date ON entries (entry_date)',
      );
      await customStatement(
        'CREATE INDEX idx_photos_entry ON photos (entry_id)',
      );
      await customStatement('CREATE INDEX idx_drive_log_at ON drive_log (at)');
    },
    // Schema 1 -> 2: Google Drive bookkeeping tables. Existing data is not
    // touched; the opener copies the file before this runs (UPD-4).
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(driveUploadedPhotos);
        await m.createTable(driveLog);
        await customStatement(
          'CREATE INDEX idx_drive_log_at ON drive_log (at)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
