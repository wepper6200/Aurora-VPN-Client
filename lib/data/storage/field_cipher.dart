import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value secret store (abstracted for tests).
abstract interface class KeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Android Keystore / Windows DPAPI-backed storage.
class SecureKeyStore implements KeyStore {
  const SecureKeyStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}

class MemoryKeyStore implements KeyStore {
  final _m = <String, String>{};

  @override
  Future<String?> read(String key) async => _m[key];

  @override
  Future<void> write(String key, String value) async => _m[key] = value;
}

/// AES-256-GCM encryption of sensitive database fields.
///
/// The data key is random, generated once and kept in platform secure storage;
/// the database only ever sees ciphertext for credentials and subscription
/// URLs.
class FieldCipher {
  FieldCipher._(this._key);

  static const _keyName = 'aurora.db.key.v1';
  static final _algo = AesGcm.with256bits();

  final SecretKey _key;

  static Future<FieldCipher> open(KeyStore store) async {
    var encoded = await store.read(_keyName);
    if (encoded == null) {
      final rnd = Random.secure();
      encoded = base64.encode(List<int>.generate(32, (_) => rnd.nextInt(256)));
      await store.write(_keyName, encoded);
    }
    return FieldCipher._(SecretKey(base64.decode(encoded)));
  }

  /// `base64(nonce ‖ ciphertext ‖ mac)`
  Future<String> encrypt(String plaintext) async {
    final box = await _algo.encrypt(utf8.encode(plaintext), secretKey: _key);
    return base64.encode(box.concatenation());
  }

  Future<String> decrypt(String encoded) async {
    final box = SecretBox.fromConcatenation(
      base64.decode(encoded),
      nonceLength: _algo.nonceLength,
      macLength: _algo.macAlgorithm.macLength,
    );
    return utf8.decode(await _algo.decrypt(box, secretKey: _key));
  }
}
