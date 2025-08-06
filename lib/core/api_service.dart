import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

class ApiService {
  final Ref ref;
  static const baseUrl = 'https://sham.shetanvpn.ru';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiService(this.ref);

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
    final contentType = response.headers['content-type'];
    final isJson = contentType != null && contentType.contains('application/json');
    dynamic body;

    if (response.body.isNotEmpty) {
      if (isJson) {
        try {
          body = jsonDecode(response.body);
        } catch (e) {
          body = response.body;
        }
      } else {
        body = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      throw UnauthorizedException(
        body is Map
          ? (body['error'] ?? body['message'] ?? 'Unauthorized')
          : body?.toString() ?? 'Unauthorized'
      );
    } else {
      throw ApiException(
        body is Map
          ? (body['error'] ?? body['message'] ?? 'Ошибка: $statusCode')
          : body?.toString() ?? 'Ошибка: $statusCode',
        statusCode,
      );
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
