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
  static const currentSchemaVersion = 3;

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
      // Schema 2 -> 3: a photo taken off an entry is marked, not deleted.
      if (from < 3) {
        await m.addColumn(photos, photos.removedAt);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _addColumnsEarlyBuildsLacked();
    },
  );

  /// Columns that databases made by early builds of the app never got, because
  /// they were added to the tables without a schema number of their own. A
  /// database at the newest number can still lack them, so this checks every
  /// time the file is opened. Adding a nullable column changes no data.
  Future<void> _addColumnsEarlyBuildsLacked() async {
    const missing = [
      // When a phone entry reached the computer (shown on the phone's entry).
      ('entries', 'synced_at', 'INTEGER NULL'),
    ];
    for (final (table, column, type) in missing) {
      final cols = await customSelect('PRAGMA table_info($table)').get();
      if (!cols.any((r) => r.read<String>('name') == column)) {
        await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
      }
    }
  }
}
