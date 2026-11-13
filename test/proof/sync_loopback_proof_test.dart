import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Phase 0 proof 3: a shelf server in the app accepts an AES-GCM encrypted
/// message from a client over localhost, using a one-time key.
void main() {
  test('encrypted message over localhost', () async {
    final algo = AesGcm.with256bits();
    final key = await algo.newSecretKey();
    final server = await shelf_io.serve((Request req) async {
      final body = await req.read().expand((c) => c).toList();
      final box = SecretBox.fromConcatenation(body,
          nonceLength: 12, macLength: 16);
      final clear = utf8.decode(await algo.decrypt(box, secretKey: key));
      return Response.ok('got:$clear');
    }, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final box = await algo.encrypt(utf8.encode('আটিয়া হ্যালো'), secretKey: key);
    final res = await http.post(
        Uri.parse('http://127.0.0.1:${server.port}/hello'),
        body: box.concatenation());
    expect(res.statusCode, 200);
    expect(utf8.decode(res.bodyBytes), 'got:আটিয়া হ্যালো');
  });
}
