import 'dart:convert';
import 'dart:isolate';

import 'package:bcrypt/bcrypt.dart';

/// Slow, salted password hashing (USR-9). Passwords are never stored or
/// logged in plain text.
class PasswordHasher {
  const PasswordHasher({this.logRounds = 10});

  /// bcrypt cost. Tests use a low value to stay fast.
  final int logRounds;

  static const minLength = 6;

  /// bcrypt only reads the first 72 bytes, so longer passwords are refused.
  static const maxBytes = 72;

  static bool isTooShort(String password) => password.length < minLength;
  static bool isTooLong(String password) =>
      utf8.encode(password).length > maxBytes;

  /// Hashing runs off the UI thread.
  Future<String> hash(String password) {
    final rounds = logRounds;
    return Isolate.run(
      () => BCrypt.hashpw(password, BCrypt.gensalt(logRounds: rounds)),
    );
  }

  Future<bool> verify(String password, String hash) {
    return Isolate.run(() {
      try {
        return BCrypt.checkpw(password, hash);
      } catch (_) {
        return false;
      }
    });
  }
}
