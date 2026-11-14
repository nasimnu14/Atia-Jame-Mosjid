// A headless "desktop" for trying the phone sync by hand, without the desktop
// app: it opens a temporary database with two users, listens like the app's
// Sync page does, and writes the current sync code to the file given as the
// second argument (it writes a new one each time a code is used).
//
//   dart run tool/sync_host.dart 10.0.2.2 /tmp/sync_code.txt
//
// 10.0.2.2 is how the Android emulator reaches this computer. For a real phone
// use this computer's Wi-Fi address instead.
import 'dart:async';
import 'dart:io';

import 'package:atia_masjid_accounts/data/database.dart';
import 'package:atia_masjid_accounts/data/photo_storage.dart';
import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/settings/settings_service.dart';
import 'package:atia_masjid_accounts/features/sync/sync_receiver.dart';
import 'package:atia_masjid_accounts/features/sync/sync_server.dart';
import 'package:atia_masjid_accounts/features/users/user_service.dart';
import 'package:atia_masjid_accounts/shared/password_hasher.dart';
import 'package:atia_masjid_accounts/data/repositories/settings_repository.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : '127.0.0.1';
  final codeFile = File(args.length > 1 ? args[1] : '/tmp/sync_code.txt');
  final dir = Directory.systemTemp.createTempSync('atia_sync_host_');
  final db = AppDatabase(NativeDatabase(File(p.join(dir.path, 'host.db'))));
  final users = UserService(db, hasher: const PasswordHasher(logRounds: 4));
  final su = await users.createSuperAdmin(
    name: 'আব্দুর রহমান',
    username: 'rahman',
    password: 'secret1',
  );
  await users.addUser(
    su,
    name: 'রাশেদুল হাসান',
    username: 'rashed',
    password: 'secret3',
    role: Role.user,
  );
  await SettingsService(db, SettingsRepository(db)).addApprover(su, 'সভাপতি');

  final server = SyncServer(
    receiver: SyncReceiver(
      db,
      PhotoStorage(Directory(p.join(dir.path, 'photos'))),
    ),
    desktopName: 'Test desktop',
    hostAddress: host,
  );
  server.events.listen((e) {
    switch (e) {
      case OfferChanged(:final offer):
        codeFile.writeAsStringSync(offer.encode());
        stdout.writeln('CODE written (port ${offer.port})');
      case PhoneConnected(:final phoneName):
        stdout.writeln('PHONE connected: $phoneName');
      case EntryReceived(:final entries, :final photos):
        stdout.writeln('RECEIVED $entries entries, $photos photos');
      case SyncFinished():
        stdout.writeln(
          'FINISHED entries=${e.entries} income=${e.income} expense=${e.expense} dup=${e.duplicates}',
        );
    }
  });
  await server.start();
  stdout.writeln('READY in ${dir.path}');
  // Print what the "desktop" holds whenever asked.
  ProcessSignal.sigusr1.watch().listen((_) async {
    final rows = await db.select(db.entries).get();
    stdout.writeln(
      'DESKTOP HAS ${rows.length} entries: ${rows.map((r) => '${r.type.name}#${r.receiptNo}=${r.amount}(${r.name})').join(', ')}',
    );
  });
  await Completer<void>().future;
}
