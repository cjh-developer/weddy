// non-web 플랫폼용 스텁. dart:html 없이 컴파일되도록 빈 구현을 제공한다.
// 실제 호출은 token_storage.dart 의 kIsWeb 분기로 차단되므로 실행되지 않는다.

void localStorageWrite(String key, String value) {}

String? localStorageRead(String key) => null;

void localStorageDelete(String key) {}
