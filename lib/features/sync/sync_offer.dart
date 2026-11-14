import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// What the QR code carries: where the desktop is, a one-time key to seal the
/// data with, and a one-time token (SYN-2, SYN-3). It is used for one sync only.
class SyncOffer {
  SyncOffer({
    required this.host,
    required this.port,
    required this.key,
    required this.token,
    required this.desktopName,
  });

  final String host;
  final int port;

  /// 32 random bytes.
  final Uint8List key;
  final String token;
  final String desktopName;

  static const _prefix = 'ATIA1.';

  /// A fresh random offer.
  factory SyncOffer.generate({
    required String host,
    required int port,
    required String desktopName,
    Random? random,
  }) {
    final r = random ?? Random.secure();
    List<int> bytes(int n) => List<int>.generate(n, (_) => r.nextInt(256));
    return SyncOffer(
      host: host,
      port: port,
      key: Uint8List.fromList(bytes(32)),
      token: base64Url.encode(bytes(18)),
      desktopName: desktopName,
    );
  }

  /// The text inside the QR code (also shown as a code to type in).
  String encode() =>
      _prefix +
      base64Url.encode(
        utf8.encode(
          jsonEncode({
            'h': host,
            'p': port,
            'k': base64Url.encode(key),
            't': token,
            'n': desktopName,
          }),
        ),
      );

  /// Null if [text] is not a sync code.
  static SyncOffer? tryDecode(String text) {
    final t = text.trim();
    if (!t.startsWith(_prefix)) {
      return null;
    }
    try {
      final m =
          jsonDecode(utf8.decode(base64Url.decode(t.substring(_prefix.length))))
              as Map<String, dynamic>;
      final key = Uint8List.fromList(base64Url.decode(m['k'] as String));
      if (key.length != 32) {
        return null;
      }
      return SyncOffer(
        host: m['h'] as String,
        port: m['p'] as int,
        key: key,
        token: m['t'] as String,
        desktopName: (m['n'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
