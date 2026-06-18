import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBase}$path');

  dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(_uri(path),
        headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(_uri(path),
        headers: _headers, body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(_uri(path),
        headers: _headers, body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _decode(res);
  }
}
