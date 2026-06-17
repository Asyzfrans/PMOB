// lib/services/api_client.dart
//
// Central HTTP client. Semua request ke Laravel API lewat sini.
// Otomatis inject Bearer token dari TokenStorage.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // ── Ganti dengan URL Laravel Anda ─────────────────
  // Development (Android emulator):  http://10.0.2.2:8000/api
  // Development (iOS simulator):     http://127.0.0.1:8000/api
  // Development (device fisik):      http://192.168.x.x:8000/api
  // Production:                       https://api.donateid.com/api
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage);

  // ── Headers ───────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (auth) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── GET ───────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: query);
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 30));
    return _handle(response);
  }

  // ── POST (JSON) ───────────────────────────────────
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 30));
    return _handle(response);
  }

  // ── PUT (JSON) ────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .put(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 30));
    return _handle(response);
  }

  // ── DELETE ────────────────────────────────────────
  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 30));
    return _handle(response);
  }

  // ── MULTIPART (untuk upload gambar) ───────────────
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    File? imageFile,
    String imageField = 'image',
    bool auth = true,
  }) async {
    final uri     = Uri.parse('$_baseUrl$path');
    final headers = await _headers(auth: auth);
    // multipart tidak pakai Content-Type json
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..fields.addAll(fields);

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        imageField,
        imageFile.path,
      ));
    }

    final streamed  = await request.send().timeout(const Duration(seconds: 60));
    final response  = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  // ── Response handler ──────────────────────────────
  Map<String, dynamic> _handle(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Laravel validation errors (422)
    final errors = body['errors'] as Map<String, dynamic>?;
    final firstError = errors?.values.first;
    final message = firstError is List
        ? firstError.first.toString()
        : (body['message'] as String? ?? 'Terjadi kesalahan.');

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }
}
