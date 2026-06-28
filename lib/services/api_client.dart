// lib/services/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // ── URL otomatis per platform ─────────────────────
  //
  // Chrome / Windows desktop → donateid.test (virtual host Laragon)
  // Android Emulator         → 10.0.2.2 (alias ke localhost komputer)
  // Device fisik             → ganti dengan IP komputer Anda di WiFi
  //
  // Ganti nama "donateid.test" jika virtual host Laragon Anda berbeda.

  static String get _baseUrl {
    if (kIsWeb) {
      // Flutter Web (Chrome, Edge) — pakai virtual host Laragon
      return 'https://donateid-api-production.up.railway.app/api';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator — 10.0.2.2 adalah alias ke localhost komputer
        return 'https://donateid-api-production.up.railway.app/api';
      }
      if (Platform.isIOS) {
        return 'http://127.0.0.1/api';
      }
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return 'http://donateid.test/api';
      }
    } catch (_) {}
    return 'http://donateid.test/api';
  }

  final TokenStorage _tokenStorage;
  ApiClient(this._tokenStorage);

  // ── Headers ───────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── GET ───────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final res = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // ── POST (JSON) ───────────────────────────────────
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http
        .post(uri,
            headers: await _headers(auth: auth), body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // ── PUT ───────────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http
        .put(uri,
            headers: await _headers(auth: auth), body: jsonEncode(body ?? {}))
        .timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // ── DELETE ────────────────────────────────────────
  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // ── MULTIPART (upload gambar) ─────────────────────
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    File? imageFile,
    String imageField = 'image',
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers(auth: auth);
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields);

    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath(imageField, imageFile.path));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  // ── Response handler ──────────────────────────────
  Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'message': res.body};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    // Parse Laravel validation errors
    final errors = body['errors'] as Map<String, dynamic>?;
    final firstErr = errors?.values.first;
    final message = firstErr is List
        ? firstErr.first.toString()
        : (body['message'] as String? ?? 'Terjadi kesalahan.');

    throw ApiException(statusCode: res.statusCode, message: message);
  }
}
