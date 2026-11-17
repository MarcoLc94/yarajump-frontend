import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int? status; // null = sin conexión
  final String message;
  @override
  String toString() => message;
}

/// Cliente HTTP de la API de Yara Jump. Guarda el JWT en el almacenamiento seguro.
class ApiClient {
  ApiClient({required this.baseUrl, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final FlutterSecureStorage _storage;
  final _http = http.Client();
  static const _tokenKey = 'api_token';

  String? _token;

  /// Se llama cuando la API responde 401 (sesión expirada).
  void Function()? onUnauthorized;

  Future<String?> loadToken() async => _token = await _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> upload(String path, String field, File file) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_headers())
      ..files.add(await http.MultipartFile.fromPath(field, file.path));
    return _run(() => _http.send(req));
  }

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final req = http.Request(method, uri)..headers.addAll(_headers(json: body != null));
    if (body != null) req.body = jsonEncode(body);
    return _run(() => _http.send(req));
  }

  Future<dynamic> _run(Future<http.StreamedResponse> Function() call) async {
    final http.StreamedResponse resp;
    try {
      resp = await call().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiException(null, 'No hay conexión con el servidor');
    } on TimeoutException {
      throw ApiException(null, 'El servidor tardó demasiado en responder');
    } on http.ClientException {
      throw ApiException(null, 'No hay conexión con el servidor');
    }

    final text = await resp.stream.bytesToString();
    final data = text.isEmpty ? null : jsonDecode(text);
    if (resp.statusCode >= 200 && resp.statusCode < 300) return data;

    if (resp.statusCode == 401 && _token != null) {
      await clearToken();
      onUnauthorized?.call();
    }
    final msg = data is Map && data['error'] is String ? data['error'] as String : 'Error ${resp.statusCode}';
    throw ApiException(resp.statusCode, msg);
  }
}
