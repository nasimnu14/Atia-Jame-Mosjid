import 'dart:math';
import 'dart:typed_data';

import 'package:atia_masjid_accounts/features/entries/photo_shrinker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List noisyJpeg(int w, int h) {
  final rnd = Random(1);
  final im = img.Image(width: w, height: h);
  for (final p in im) {
    p
      ..r = rnd.nextInt(256)
      ..g = rnd.nextInt(256)
      ..b = rnd.nextInt(256);
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 95));
}

void main() {
  const shrinker = PhotoShrinker();

  test(
    'INC-9: a large photo is shrunk to at most 1600 px and is smaller',
    () async {
      final big = noisyJpeg(3200, 2400);
      final out = await shrinker.shrink(big);
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 1600);
      expect(decoded.height, 1200); // same shape
      expect(out.length, lessThan(big.length));
    },
  );

  test('a tall photo is limited by its height', () async {
    final out = await shrinker.shrink(noisyJpeg(1800, 3600));
    final d = img.decodeJpg(out)!;
    expect((d.width, d.height), (800, 1600));
  });

  test('a small photo is kept as it is', () async {
    final small = Uint8List.fromList(
      img.encodePng(img.Image(width: 300, height: 200)),
    );
    expect(await shrinker.shrink(small), small);
  });

  test(
    'a photo within the pixel limit but heavy is recompressed, still readable',
    () async {
      final heavy = noisyJpeg(1500, 1500); // several MB of noise
      expect(heavy.length, greaterThan(400 * 1024));
      final out = await shrinker.shrink(heavy);
      expect(out.length, lessThan(heavy.length));
      expect(img.decodeJpg(out)!.width, 1500);
    },
  );

  test('a file that is not a photo is refused', () async {
    await expectLater(
      shrinker.shrink(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<PhotoUnreadableException>()),
    );
  });
}
