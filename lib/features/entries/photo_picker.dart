import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';

/// Where photos come from. The desktop picks image files; the phone can take
/// a photo with the camera or pick from the gallery (MOB-2). Screens use this
/// interface so tests can supply photos without a file dialog.
abstract class PhotoPicker {
  /// Returns the raw bytes of the chosen photos (empty when cancelled).
  Future<List<Uint8List>> pick(BuildContext context, {required int maxCount});
}

class PlatformPhotoPicker implements PhotoPicker {
  const PlatformPhotoPicker();

  @override
  Future<List<Uint8List>> pick(
    BuildContext context, {
    required int maxCount,
  }) async {
    if (maxCount <= 0) return const [];
    if (Platform.isAndroid || Platform.isIOS) {
      final source = await showAndroidSourceChoice(context);
      if (source == null) return const [];
      final picker = ImagePicker();
      if (source == ImageSource.camera) {
        final f = await picker.pickImage(source: ImageSource.camera);
        return f == null ? const [] : [await f.readAsBytes()];
      }
      final files = await picker.pickMultiImage(
        limit: maxCount >= 2 ? maxCount : null,
      );
      return [for (final f in files.take(maxCount)) await f.readAsBytes()];
    }
    const group = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
      uniformTypeIdentifiers: ['public.image'],
    );
    final files = await openFiles(acceptedTypeGroups: [group]);
    return [for (final f in files.take(maxCount)) await f.readAsBytes()];
  }
}

/// Bottom sheet: camera or gallery.
Future<ImageSource?> showAndroidSourceChoice(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheetSafe<ImageSource>(context, [
    (l.takePhoto, ImageSource.camera),
    (l.pickFromGallery, ImageSource.gallery),
  ]);
}

Future<T?> showModalBottomSheetSafe<T>(
  BuildContext context,
  List<(String, T)> options,
) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in options)
            ListTile(
              title: Text(label),
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    ),
  );
}
