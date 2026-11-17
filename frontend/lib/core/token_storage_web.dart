import 'dart:html' as html;

/// Web counterpart of [TokenStorage] (see token_storage_io.dart). Plain
/// `localStorage` instead of `flutter_secure_storage`: that package encrypts
/// values via the Web Crypto API, which browsers only expose in a "secure
/// context" (https://, or http://localhost) — a plain http:// origin on a
/// LAN IP (e.g. testing over Wi-Fi at http://192.168.x.x) has no
/// `window.crypto.subtle`, so every write/read throws and login/register
/// silently fail right after the backend already accepted them. localStorage
/// has no such restriction and is already same-origin-isolated like any
/// other browser storage, so this trades nothing meaningful away on web.
class TokenStorage {
  static const _key = 'biotrack_access_token';

  Future<String?> read() async => html.window.localStorage[_key];

  Future<void> write(String token) async => html.window.localStorage[_key] = token;

  Future<void> clear() async => html.window.localStorage.remove(_key);
}
