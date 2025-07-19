import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  static const baseUrl = 'http://95.214.10.8:3000';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  String? _token;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _token = await _storage.read(key: 'token');
    _isInitialized = true;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      await _storage.write(key: 'token', value: token);
    } else {
      await _storage.delete(key: 'token');
    }
  }

  Future<dynamic> get(String path, {bool auth = false}) async {
    await init();
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    await init();
    final url = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException(body?['error'] ?? body?['message'] ?? 'Unauthorized');
    } else {
      throw ApiException(body?['error'] ?? body?['message'] ?? 'Ошибка: $statusCode', statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}
