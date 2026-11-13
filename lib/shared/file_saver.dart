import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Lets the user choose where a file is saved (PDF-5). Screens use this
/// interface so tests can capture the file without a save dialog.
abstract class FileSaver {
  /// Returns where it was saved (or a name for a share), or null if the user
  /// cancelled.
  Future<String?> save(
    BuildContext context, {
    required String suggestedName,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  });
}

class PlatformFileSaver implements FileSaver {
  const PlatformFileSaver();

  @override
  Future<String?> save(
    BuildContext context, {
    required String suggestedName,
    required Uint8List bytes,
    required String extension,
    required String mimeType,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // A phone has no "save as" dialog: hand the file to the share sheet,
      // which can save it to Files or Drive, or send it.
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, '$suggestedName.$extension'));
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
      );
      return file.path;
    }
    final location = await getSaveLocation(
      suggestedName: '$suggestedName.$extension',
      acceptedTypeGroups: [
        XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
      ],
    );
    if (location == null) return null;
    var path = location.path;
    if (!path.toLowerCase().endsWith('.$extension')) path = '$path.$extension';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
