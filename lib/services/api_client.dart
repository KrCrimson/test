import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'session.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? Config.apiBaseUrl;

  Future<http.Response> get(String path, {Map<String, String>? headers, Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await Session.getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (headers != null) h.addAll(headers);
    final response = await http.get(uri, headers: h).timeout(timeout ?? const Duration(seconds: 10));
    return response;
  }

  Future<http.Response> post(String path, {Map<String, String>? headers, Object? body, Duration? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await Session.getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (headers != null) h.addAll(headers);
    final b = body is String ? body : json.encode(body);
    final response = await http.post(uri, headers: h, body: b).timeout(timeout ?? const Duration(seconds: 10));
    return response;
  }

  // Puedes añadir put, delete, etc. según necesites
}
