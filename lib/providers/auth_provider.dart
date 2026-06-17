// lib/providers/auth_provider.dart
// Tidak ada Firebase stream — pakai REST + SharedPreferences token

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthStatus   _status = AuthStatus.initial;
  UserSession? _currentUser;
  String?      _errorMessage;

  AuthProvider(this._service);

  AuthStatus   get status       => _status;
  UserSession? get currentUser  => _currentUser;
  String?      get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin         => _currentUser?.role == UserRole.admin;
  bool get isFundraiser    => _currentUser?.role == UserRole.fundraiser;
  bool get isDonatur       => _currentUser?.role == UserRole.donatur;

  // ── Init: dipanggil sekali di main.dart ──────────
  // Coba restore session dari SharedPreferences,
  // lalu validasi token ke server (GET /api/me)
  Future<void> init() async {
    _status = AuthStatus.initial;
    notifyListeners();

    // 1. Cek token tersimpan
    if (!_service.hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // 2. Ada token — tampilkan cached user dulu (UX cepat)
    _currentUser = _service.savedUser;
    if (_currentUser != null) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }

    // 3. Validasi token ke server di background
    final fresh = await _service.refreshSession();
    if (fresh != null) {
      _currentUser = fresh;
      _status      = AuthStatus.authenticated;
    } else {
      // Token expired/invalid
      _currentUser = null;
      _status      = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.login(email, password);
    if (result.ok) {
      _currentUser = result.user;
      _status      = AuthStatus.authenticated;
    } else {
      _errorMessage = result.message;
      _status       = AuthStatus.unauthenticated;
    }
    notifyListeners();
    return result.ok;
  }

  // ── Register ──────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.register(
      name: name, email: email, password: password, role: role,
    );
    if (result.ok) {
      _currentUser = result.user;
      _status      = AuthStatus.authenticated;
    } else {
      _errorMessage = result.message;
      _status       = AuthStatus.unauthenticated;
    }
    notifyListeners();
    return result.ok;
  }

  // ── Logout ────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _currentUser = null;
    _status      = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
