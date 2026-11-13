import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PhotoUnreadableException implements Exception {
  @override
  String toString() => 'The file is not a readable photo';
}

/// Shrinks a large photo before it is saved (INC-9), so it stays clear enough
/// to read a receipt but takes less space in backups and syncs. Applies on the
/// desktop and the phone alike.
class PhotoShrinker {
  const PhotoShrinker({
    this.maxSide = 1600,
    this.quality = 82,
    this.keepBelowBytes = 400 * 1024,
  });

  /// Longest side in pixels after shrinking.
  final int maxSide;
  final int quality;

  /// A photo already this small (and within [maxSide]) is stored as it is.
  final int keepBelowBytes;

  Future<Uint8List> shrink(Uint8List bytes) =>
      Isolate.run(() => _shrink(bytes, maxSide, quality, keepBelowBytes));
}

Uint8List _shrink(Uint8List bytes, int maxSide, int quality, int keepBelow) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    // A damaged or unsupported file can make the decoder throw.
    decoded = null;
  }
  if (decoded == null) throw PhotoUnreadableException();
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest <= maxSide && bytes.length <= keepBelow) return bytes;
  if (longest > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: maxSide,
            interpolation: img.Interpolation.average,
          );
  }
  final out = Uint8List.fromList(img.encodeJpg(image, quality: quality));
  // Never make a small, already-compressed photo bigger.
  return out.length < bytes.length || longest > maxSide ? out : bytes;
}
