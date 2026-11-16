import 'package:drift/drift.dart';

/// The three roles (USR-2). One Super Admin only (USR-3).
enum Role { superAdmin, admin, user }

enum EntryType { income, expense }

enum EntryStatus { active, cancelled }

/// People who can sign in. Never deleted, only disabled (USR-6).
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Stored lower-case so sign-in is case-insensitive.
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => textEnum<Role>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSignInAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Every income and expense. [id] is a UUID created on the device that made
/// the entry; the receipt number is NOT the identity (plan rule 2).
/// [amount] is whole Taka (plan rule 3).
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<EntryType>()();
  IntColumn get receiptNo => integer()();

  /// `yyyy-MM-dd`, so ranges can be compared as text.
  TextColumn get entryDate => text()();

  /// Donor (income) or payee (expense). Empty = unknown (INC-3).
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Expense only: what the money was for (বিবরণ).
  TextColumn get purpose => text().nullable()();

  /// Expense only: copied as text so later list edits don't change it (EXP-8).
  TextColumn get approverName => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get address => text().nullable()();
  TextColumn get status =>
      textEnum<EntryStatus>().withDefault(Constant(EntryStatus.active.name))();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get editedBy => text().nullable()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  /// Which device made the entry (desktop or a phone).
  TextColumn get deviceId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  /// On the desktop: when a phone entry arrived (shown as "synced to the
  /// computer at ..."). Null for entries made on this device.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Set when a synced phone entry arrived with a receipt number the desktop
  /// already had (SYN-8).
  BoolColumn get isDuplicate => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Up to 10 per entry (INC-6). The file itself lives next to the database.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(Entries, #id)();
  TextColumn get fileName => text()();
  TextColumn get label => text()();
  IntColumn get position => integer()();

  /// Set when a photo is taken off an entry. The row and the file stay (plan
  /// rule 4: nothing is ever deleted); the photo is just no longer shown.
  DateTimeColumn get removedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The expense approver list (EXP-6). Disabled, never deleted.
class Approvers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single values: language, opening balance, last backup time, ...
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One row per phone sync (SYN-9).
class SyncLog extends Table {
  TextColumn get id => text()();
  TextColumn get phoneName => text()();
  DateTimeColumn get at => dateTime()();
  IntColumn get entriesReceived => integer()();
  IntColumn get photosReceived => integer()();
  IntColumn get duplicates => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Photos already uploaded to Google Drive, per Google account. A photo file
/// is uploaded once and never again, so each 4-hour backup only uploads the
/// database and new photos (plan Section 5, Phase 4). Added in schema 2.
class DriveUploadedPhotos extends Table {
  TextColumn get account => text()();
  TextColumn get entryId => text()();
  TextColumn get fileName => text()();
  TextColumn get driveFileId => text()();
  DateTimeColumn get uploadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {account, entryId, fileName};
}

/// What the app did with Google Drive: backups and Excel uploads, shown on the
/// Backup and Excel screens (BAK-5, XLS-8). Added in schema 2.
class DriveLog extends Table {
  TextColumn get id => text()();
  DateTimeColumn get at => dateTime()();

  /// `backup`, `excel_daily` or `excel_manual`.
  TextColumn get kind => text()();
  TextColumn get description => text()();
  BoolColumn get ok => boolean()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
