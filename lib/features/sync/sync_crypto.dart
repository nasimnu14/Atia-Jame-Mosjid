import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The data was not made with our key, or was changed on the way.
class SyncAuthException implements Exception {
  @override
  String toString() => 'Wrong key or damaged data';
}

/// AES-256-GCM with the one-time key from the QR code. Everything sent over
/// the Wi-Fi is sealed with it, so someone else on the same network cannot read
/// or change entries or account data (plan Risk 7). GCM also detects any change.
///
/// Each message is bound to its purpose ([aad], e.g. the URL path), so a
/// captured message cannot be replayed to another endpoint.
class SyncCrypto {
  SyncCrypto(List<int> keyBytes)
    : assert(keyBytes.length == 32),
      _key = SecretKey(keyBytes);

  final SecretKey _key;
  static final _aes = AesGcm.with256bits();

  /// nonce (12 bytes) + encrypted data + tag (16 bytes).
  Future<Uint8List> seal(List<int> plain, {required String aad}) async {
    final box = await _aes.encrypt(
      plain,
      secretKey: _key,
      aad: utf8.encode(aad),
    );
    return Uint8List.fromList(box.concatenation());
  }

  Future<Uint8List> open(List<int> data, {required String aad}) async {
    try {
      final box = SecretBox.fromConcatenation(
        data,
        nonceLength: 12,
        macLength: 16,
      );
      return Uint8List.fromList(
        await _aes.decrypt(box, secretKey: _key, aad: utf8.encode(aad)),
      );
    } catch (_) {
      throw SyncAuthException();
    }
  }

  Future<Uint8List> sealJson(Object json, {required String aad}) =>
      seal(utf8.encode(jsonEncode(json)), aad: aad);

  Future<Map<String, dynamic>> openJson(
    List<int> data, {
    required String aad,
  }) async =>
      jsonDecode(utf8.decode(await open(data, aad: aad)))
          as Map<String, dynamic>;
}
