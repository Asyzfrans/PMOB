// lib/services/token_storage.dart
//
// Menyimpan Sanctum token dan data user session ke SharedPreferences.
// Ini satu-satunya file yang masih pakai SharedPreferences —
// hanya untuk persist token antar session, bukan untuk data.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class TokenStorage {
  static const _keyToken   = 'donateid_token';
  static const _keyUser    = 'donateid_user';

  final SharedPreferences _prefs;
  TokenStorage(this._prefs);

  // ── Token ─────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_keyToken);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_keyToken);
  }

  // ── User session ──────────────────────────────────
  Future<void> saveUser(UserSession user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  UserSession? getUser() {
    final raw = _prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // ── Clear all (logout) ────────────────────────────
  Future<void> clear() async {
    await clearToken();
    await clearUser();
  }

  bool get hasToken => _prefs.containsKey(_keyToken);
}
