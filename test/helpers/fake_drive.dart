import 'dart:typed_data';

import 'package:atia_masjid_accounts/features/google_drive/drive_client.dart';

/// An in-memory Google Drive for tests. Files, folders, "no internet" and
/// "storage full" can be controlled, and uploads can be made to stop halfway.
class FakeDrive {
  final Map<String, _Node> _nodes = {};
  int _seq = 0;
  DateTime Function() clock = DateTime.now;

  /// While true every call throws an offline [DriveException].
  bool offline = false;

  /// Makes the n-th next upload fail (1 = the very next).
  int failUploadNumber = 0;
  int uploadCount = 0;

  DriveClient client(String email) => FakeDriveClient._(this, email);

  Iterable<DriveFile> get files =>
      _nodes.values.where((n) => !n.isFolder).map((n) => n.toFile());

  List<DriveFile> filesIn(String folderName, {String? account}) {
    final folder = _nodes.values
        .where((n) => n.isFolder && n.name == folderName)
        .toList();
    if (folder.isEmpty) return [];
    return _nodes.values
        .where((n) => !n.isFolder && folder.any((f) => f.id == n.parent))
        .map((n) => n.toFile())
        .toList()
      ..sort((a, b) => b.createdTime.compareTo(a.createdTime));
  }

  Uint8List? bytesOf(String id) => _nodes[id]?.bytes;

  /// Moves a file's recorded creation time (to test one-year clean-up).
  void setCreated(String id, DateTime t) => _nodes[id]!.created = t;
}

class _Node {
  _Node(
    this.id,
    this.name,
    this.parent,
    this.isFolder,
    this.created,
    this.bytes,
    this.mime,
  );
  final String id;
  final String name;
  final String? parent;
  final bool isFolder;
  DateTime created;
  final Uint8List? bytes;
  final String? mime;
  DriveFile toFile() =>
      DriveFile(id: id, name: name, createdTime: created, size: bytes?.length);
}

class FakeDriveClient implements DriveClient {
  FakeDriveClient._(this._d, this.accountEmail);
  final FakeDrive _d;
  @override
  final String accountEmail;

  void _check() {
    if (_d.offline) throw DriveException('No internet', offline: true);
  }

  // Each account has its own Drive: folders are namespaced by account.
  String _ns(String id) => '$accountEmail|$id';

  @override
  Future<String> ensureFolder(String name, {String? parentId}) async {
    _check();
    for (final n in _d._nodes.values) {
      if (n.isFolder &&
          n.name == name &&
          n.parent == parentId &&
          n.id.startsWith('$accountEmail|')) {
        return n.id;
      }
    }
    final id = _ns('f${++_d._seq}');
    _d._nodes[id] = _Node(id, name, parentId, true, _d.clock(), null, null);
    return id;
  }

  @override
  Future<DriveFile> upload({
    required String folderId,
    required String name,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    _check();
    _d.uploadCount++;
    if (_d.failUploadNumber > 0) {
      _d.failUploadNumber--;
      if (_d.failUploadNumber == 0) throw DriveException('Upload stopped');
    }
    final id = _ns('x${++_d._seq}');
    final node = _Node(
      id,
      name,
      folderId,
      false,
      _d.clock(),
      Uint8List.fromList(bytes),
      mimeType,
    );
    _d._nodes[id] = node;
    return node.toFile();
  }

  @override
  Future<List<DriveFile>> list(String folderId) async {
    _check();
    return _d._nodes.values
        .where((n) => n.parent == folderId && !n.isFolder)
        .map((n) => n.toFile())
        .toList()
      ..sort((a, b) => b.createdTime.compareTo(a.createdTime));
  }

  @override
  Future<Uint8List> download(String fileId) async {
    _check();
    final n = _d._nodes[fileId];
    if (n == null || n.bytes == null) throw DriveException('Not found');
    return n.bytes!;
  }

  @override
  Future<void> delete(String fileId) async {
    _check();
    _d._nodes.remove(fileId);
  }
}

/// A [DriveAuth] that hands out fake clients.
class FakeDriveAuth implements DriveAuth {
  FakeDriveAuth(
    this.drive, {
    this.stored,
    this.nextAccount = 'mosque@example.com',
  });
  final FakeDrive drive;
  String? stored;
  String nextAccount;
  bool configured = true;
  int connectCalls = 0;

  @override
  bool get isConfigured => configured;

  @override
  Future<DriveClient?> restore() async =>
      stored == null ? null : drive.client(stored!);

  @override
  Future<DriveClient> connect() async {
    connectCalls++;
    stored = nextAccount;
    return drive.client(nextAccount);
  }

  @override
  Future<void> disconnect() async => stored = null;
}

/// A placeholder [DriveFile] for tests that never reach Drive.
class DriveFileStub {
  static DriveFile make() =>
      DriveFile(id: 'x', name: 'x', createdTime: DateTime(2026));
}
