import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pozzo/core/network/access_token_provider.dart';
import 'package:pozzo/core/network/api_exception.dart';

/// HTTP client of the Pozzo RESTful services. Every feature API goes through it, so the bearer token,
/// the language of the messages, the timeouts and the error format are handled in one place.
class ApiClient {
  ApiClient({required this.tokenProvider, http.Client? client}) : _client = client ?? http.Client();

  /// The deployed backend, documented at https://api-kerolabs.duckdns.org/swagger-ui/index.html.
  static const String baseUrl = 'https://api-kerolabs.duckdns.org/api/v1/';

  final AccessTokenProvider tokenProvider;
  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Sends one file as `multipart/form-data` in the field [field], as the photo and receipt endpoints expect.
  Future<dynamic> multipart(
    String method,
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) {
    return _guard(path, () async {
      final request = http.MultipartRequest(method, _uri(path))
        ..headers.addAll(_headers(path, json: false))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      // Writing gets longer, so a receipt image uploads on a slow network.
      final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
      return http.Response.fromStream(streamed);
    });
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  /// Requesting a verification code is public, so it never carries a token.
  Map<String, String> _headers(String path, {bool json = true}) {
    final token = tokenProvider.currentToken;
    return {
      'Accept': 'application/json',
      'Accept-Language': 'es',
      if (json) 'Content-Type': 'application/json',
      if (token != null && !path.startsWith('auth/codes')) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) {
    return _guard(path, () {
      final request = http.Request(method, _uri(path, query))..headers.addAll(_headers(path));
      if (body != null) request.body = jsonEncode(body);
      return _client.send(request).timeout(const Duration(seconds: 30)).then(http.Response.fromStream);
    });
  }

  /// Turns the answer into its decoded JSON body, or throws an [ApiException] with the backend's code
  /// and message, or a readable message when there is no connection.
  Future<dynamic> _guard(String path, Future<http.Response> Function() call) async {
    final http.Response response;
    try {
      response = await call();
    } on TimeoutException {
      throw _networkError;
    } on http.ClientException {
      throw _networkError;
    }

    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Endpoints that answer 204 have no body.
      return text.isEmpty ? null : jsonDecode(text);
    }

    // A 401 from an auth route is a wrong code, not an expired session.
    if (response.statusCode == 401 && tokenProvider.currentToken != null && !path.startsWith('auth/')) {
      tokenProvider.onUnauthorized();
    }

    Map<String, dynamic>? error;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) error = decoded;
    } on FormatException {
      error = null;
    }
    throw ApiException(
      status: response.statusCode,
      code: error?['code'] as String? ?? 'HTTP_${response.statusCode}',
      message: error?['message'] as String? ?? 'Ocurrió un error. Inténtalo de nuevo.',
      details: error?['details'] as String?,
    );
  }

  static const _networkError = ApiException(
    status: 0,
    code: 'NETWORK_ERROR',
    message: 'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
  );
}
