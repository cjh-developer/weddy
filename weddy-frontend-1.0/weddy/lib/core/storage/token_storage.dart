import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT 토큰을 기기의 안전한 저장소(Keychain / Keystore)에 보관하는 클래스.
///
/// flutter_secure_storage를 래핑하여 토큰 관련 작업을 단일 책임으로 캡슐화한다.
/// Riverpod Provider([tokenStorageProvider])를 통해 싱글톤으로 주입받아 사용한다.
/// 직접 인스턴스화 시에는 Provider에서 생명주기를 관리하지 않으므로 주의한다.
///
/// 사용 예:
/// ```dart
/// // Provider 주입 (권장)
/// final storage = ref.read(tokenStorageProvider);
/// await storage.saveAccessToken('eyJhbGci...');
/// final token = await storage.getAccessToken();
/// ```
class TokenStorage {
  // static const 로 공유 인스턴스를 두면 TokenStorage 가 여러 개 생성될 경우에도
  // 동일한 FlutterSecureStorage 를 바라보게 되어 숨겨진 결합이 생긴다.
  // Provider 에서 싱글톤을 보장하므로 인스턴스 필드로 유지한다.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // Android: EncryptedSharedPreferences 사용 (API 23+)
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    // iOS: 기본 접근성(first unlock 이후)으로 Keychain 접근.
    // 앱 그룹 공유가 필요하면 groupId 를 설정한다.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // 저장 키 - 오타 방지를 위해 static const로 중앙 관리.
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';

  /// Access Token을 안전한 저장소에 저장한다.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Refresh Token을 안전한 저장소에 저장한다.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// 저장된 Access Token을 반환한다.
  /// 저장된 값이 없으면 null을 반환한다.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  /// 저장된 Refresh Token을 반환한다.
  /// 저장된 값이 없으면 null을 반환한다.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  /// Access Token과 Refresh Token을 모두 삭제한다.
  /// 로그아웃 또는 인증 만료 시 호출한다.
  Future<void> clearTokens() async {
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
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }
}
