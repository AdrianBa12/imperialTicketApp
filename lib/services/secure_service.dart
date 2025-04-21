import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';


  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }


  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }


  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<void> storeToken(String token) async {
    await FlutterSecureStorage().write(key: _tokenKey, value: token);
  }

  Future<void> saveProfileImageUrl(String url) async {
    await _storage.write(key: 'profileImageUrl', value: url);
  }

  Future<String?> getProfileImageUrl() async {
    return await _storage.read(key: 'profileImageUrl');
  }

  Future<void> deleteProfileImageUrl() async {
    await _storage.delete(key: 'profileImageUrl');
  }

}