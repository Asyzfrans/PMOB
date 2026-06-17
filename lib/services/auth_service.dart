// lib/services/auth_service.dart
// REST version — tidak ada Firebase

import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthResult {
  final bool ok;
  final String? message;
  final UserSession? user;

  const AuthResult.success(this.user) : ok = true, message = null;
  const AuthResult.failure(this.message) : ok = false, user = null;
}

class AuthService {
  final ApiClient      _api;
  final TokenStorage   _storage;

  AuthService(this._api, this._storage);

  // Cek apakah ada token tersimpan (restore session saat app buka)
  UserSession? get savedUser => _storage.getUser();
  bool get hasToken          => _storage.hasToken;

  // ── Register ──────────────────────────────────────
  // POST /api/register
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final res = await _api.post('/register', body: {
        'name':     name.trim(),
        'email':    email.trim(),
        'password': password,
        'role':     role.name,
      }, auth: false);

      final session = UserSession.fromJson(res['user'] as Map<String, dynamic>);
      await _storage.saveToken(res['token'] as String);
      await _storage.saveUser(session);
      return AuthResult.success(session);

    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Gagal terhubung ke server.');
    }
  }

  // ── Login ─────────────────────────────────────────
  // POST /api/login
  Future<AuthResult> login(String email, String password) async {
    try {
      final res = await _api.post('/login', body: {
        'email':    email.trim(),
        'password': password,
      }, auth: false);

      final session = UserSession.fromJson(res['user'] as Map<String, dynamic>);
      await _storage.saveToken(res['token'] as String);
      await _storage.saveUser(session);
      return AuthResult.success(session);

    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Gagal terhubung ke server.');
    }
  }

  // ── Logout ────────────────────────────────────────
  // POST /api/logout
  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {}
    await _storage.clear();
  }

  // ── Refresh session dari server ───────────────────
  // GET /api/me — dipanggil saat app dibuka untuk validasi token
  Future<UserSession?> refreshSession() async {
    try {
      final res     = await _api.get('/me');
      final session = UserSession.fromJson(res['user'] as Map<String, dynamic>);
      await _storage.saveUser(session);
      return session;
    } on ApiException catch (e) {
      // 401 = token expired/invalid
      if (e.statusCode == 401) await _storage.clear();
      return null;
    } catch (_) {
      // Offline — kembalikan data tersimpan
      return _storage.getUser();
    }
  }
}
