import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class SecureSession extends LocalStorage {
  const SecureSession();
  static const _storage = FlutterSecureStorage();
  static const _key = 'simplesqr.auth.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
    _storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
