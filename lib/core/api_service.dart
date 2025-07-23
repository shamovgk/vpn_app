import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_provider.dart'; // импорт tokenProvider

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref); // ref нужен для доступа к tokenProvider
});

class ApiService {
  final Ref ref;
  static const baseUrl = 'http://95.214.10.8:3000';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiService(this.ref);

  // Чтение токена только при необходимости
  Future<dynamic> get(String path, {bool auth = false}) async {
    final url = Uri.parse('$baseUrl$path');
    final token = ref.read(tokenProvider);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);
    return _processResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final url = Uri.parse('$baseUrl$path');
    final token = ref.read(tokenProvider);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    return _processResponse(response);
  }

  Future<void> saveToken(String? token) async {
    if (token != null) {
      await _storage.write(key: 'token', value: token);
    } else {
      await _storage.delete(key: 'token');
    }
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
