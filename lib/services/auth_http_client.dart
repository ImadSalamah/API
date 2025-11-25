import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Re-export http types so existing `http.*` usages keep working.
export 'package:http/http.dart';

/// HTTP client that automatically attaches the saved auth token to every request.
class AuthHttpClient extends http.BaseClient {
  AuthHttpClient(this._inner);

  final http.Client _inner;

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _getToken();

    if (token != null &&
        token.isNotEmpty &&
        !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Default content type if caller did not provide one.
    request.headers.putIfAbsent('Content-Type', () => 'application/json');

    return _inner.send(request);
  }
}

// Shared instance used across the app.
final AuthHttpClient authHttpClient = AuthHttpClient(http.Client());

// Convenience helpers mirroring the common http methods.
Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    authHttpClient.get(url, headers: headers);

Future<http.Response> post(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    authHttpClient.post(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> put(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    authHttpClient.put(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> patch(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    authHttpClient.patch(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> delete(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    authHttpClient.delete(url,
        headers: headers, body: body, encoding: encoding);
