import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 웹: dart:html의 localStorage 헬퍼 사용.
// 네이티브: 빈 스텁 (kIsWeb 분기로 실제 호출되지 않음).
import '_local_storage_stub.dart'
    if (dart.library.html) '_local_storage.dart';

/// JWT 토큰을 플랫폼에 맞는 저장소에 보관하는 클래스.
///
/// - 웹(Chrome 등): 브라우저 localStorage 사용.
///   flutter_secure_storage 의 Web Crypto API 호출(OperationError)을 우회한다.
/// - Android: EncryptedSharedPreferences (API 23+)
/// - iOS: Keychain (first_unlock 접근성)
///
/// Riverpod [tokenStorageProvider]를 통해 싱글톤으로 주입받아 사용한다.
class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';

  /// Access Token을 저장한다.
  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      localStorageWrite(_keyAccessToken, token);
      return;
    }
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Refresh Token을 저장한다.
  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      localStorageWrite(_keyRefreshToken, token);
      return;
    }
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// 저장된 Access Token을 반환한다. 없으면 null.
  Future<String?> getAccessToken() async {
    if (kIsWeb) return localStorageRead(_keyAccessToken);
    return _storage.read(key: _keyAccessToken);
  }

  /// 저장된 Refresh Token을 반환한다. 없으면 null.
  Future<String?> getRefreshToken() async {
    if (kIsWeb) return localStorageRead(_keyRefreshToken);
    return _storage.read(key: _keyRefreshToken);
  }

  /// Access Token과 Refresh Token을 모두 삭제한다.
  Future<void> clearTokens() async {
    if (kIsWeb) {
      localStorageDelete(_keyAccessToken);
      localStorageDelete(_keyRefreshToken);
      return;
    }
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  /// Access Token과 Refresh Token을 한 번에 저장한다.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) {
      localStorageWrite(_keyAccessToken, accessToken);
      localStorageWrite(_keyRefreshToken, refreshToken);
      return;
    }
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }
}
