import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu cặp token đăng nhập trong vùng nhớ bảo mật (Keychain/Keystore).
/// JWT tuyệt đối không được lưu ở shared_preferences.
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  final FlutterSecureStorage _storage;
  const TokenStorage(this._storage);

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  /// [refreshToken] null (backend chưa hỗ trợ) thì xóa refresh token cũ nếu có
  Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken == null) {
      await _storage.delete(key: _refreshKey);
    } else {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  /// Xóa cả hai token (đăng xuất hoặc phiên hết hạn)
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
