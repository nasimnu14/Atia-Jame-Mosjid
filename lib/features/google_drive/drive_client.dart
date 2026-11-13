import 'dart:typed_data';

/// A file kept in Google Drive.
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    required this.createdTime,
    this.size,
  });
  final String id;
  final String name;
  final DateTime createdTime;
  final int? size;
}

/// The few Google Drive actions the app needs. Everything else in the app talks
/// to this interface, so backup, restore and Excel upload can be tested with a
/// fake and never depend on Google being reachable.
///
/// Only files the app itself created are visible to it (the `drive.file`
/// permission), so the app can never read or change the user's other files.
abstract class DriveClient {
  /// The Google account these files belong to (e.g. an e-mail address).
  String get accountEmail;

  /// The id of the folder called [name] inside [parentId] (or at the top),
  /// creating it if it does not exist yet.
  Future<String> ensureFolder(String name, {String? parentId});

  /// Uploads a new file. An existing file with the same name is NOT replaced.
  Future<DriveFile> upload({
    required String folderId,
    required String name,
    required Uint8List bytes,
    required String mimeType,
  });

  /// Files directly inside [folderId], newest first.
  Future<List<DriveFile>> list(String folderId);

  Future<Uint8List> download(String fileId);

  Future<void> delete(String fileId);
}

/// Thrown when Drive cannot be reached or refuses (no internet, signed out,
/// storage full). The message is shown to the user.
class DriveException implements Exception {
  DriveException(this.message, {this.offline = false});
  final String message;

  /// True when the cause is a missing internet connection.
  final bool offline;
  @override
  String toString() => message;
}

/// Connecting this app to a Google account (BAK-1).
abstract class DriveAuth {
  /// Whether this build knows how to sign in to Google at all (the OAuth client
  /// is configured, see docs/setup-notes.md).
  bool get isConfigured;

  /// The account connected earlier, restored silently; null if none.
  Future<DriveClient?> restore();

  /// Opens Google's sign-in page and waits for the user (BAK-1, BAK-8).
  Future<DriveClient> connect();

  /// Forgets the connection on this computer. Files in Drive stay.
  Future<void> disconnect();
}
