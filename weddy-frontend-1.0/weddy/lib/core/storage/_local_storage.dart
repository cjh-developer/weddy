// 브라우저 localStorage 헬퍼 함수 (web 전용).
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void localStorageWrite(String key, String value) =>
    html.window.localStorage[key] = value;

String? localStorageRead(String key) => html.window.localStorage[key];

void localStorageDelete(String key) => html.window.localStorage.remove(key);
