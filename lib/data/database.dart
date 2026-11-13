import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Entries, Photos, Approvers, Settings, SyncLog])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Bump this and add a step to [migration] whenever a table changes.
  /// Add a test in test/data/migration_test.dart for every step.
  static const currentSchemaVersion = 1;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
