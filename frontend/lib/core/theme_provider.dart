import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the app-wide dark-mode preference and persists it locally (same
/// storage mechanism as the auth token, just a different key) so it
/// survives app restarts.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'biotrack_dark_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isDark = false;

  Future<void> bootstrap() async {
    final stored = await _storage.read(key: _key);
    isDark = stored == 'true';
    notifyListeners();
  }

  Future<void> toggle(bool value) async {
    isDark = value;
    notifyListeners();
    await _storage.write(key: _key, value: value.toString());
  }
}
