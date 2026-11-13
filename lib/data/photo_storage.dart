import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Photo files live in a folder next to the database (plan Section 3); the
/// database only holds their names.
class PhotoStorage {
  PhotoStorage(this.dir);
  final Directory dir;
  static const _uuid = Uuid();

  File fileFor(String entryId, String fileName) =>
      File(p.join(dir.path, entryId, fileName));

  /// Writes the bytes (already shrunk, INC-9) and returns the file name.
  /// Written to a temp name then renamed, so a crash never leaves half a photo.
  Future<String> save(
    String entryId,
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    final name = '${_uuid.v4()}.$extension';
    final folder = Directory(p.join(dir.path, entryId))
      ..createSync(recursive: true);
    final tmp = File(p.join(folder.path, '$name.part'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(folder.path, name));
    return name;
  }

  /// Saves a photo under a known name (used by restore and sync).
  Future<void> saveAs(String entryId, String fileName, Uint8List bytes) async {
    final folder = Directory(p.join(dir.path, entryId))
      ..createSync(recursive: true);
    final tmp = File(p.join(folder.path, '$fileName.part'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(folder.path, fileName));
  }

  Future<Uint8List?> read(String entryId, String fileName) async {
    final f = fileFor(entryId, fileName);
    return f.existsSync() ? f.readAsBytes() : null;
  }

  bool exists(String entryId, String fileName) =>
      fileFor(entryId, fileName).existsSync();
}
