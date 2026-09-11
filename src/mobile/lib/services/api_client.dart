import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asa_connect/core/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = AppConstants.defaultApiBaseUrl;
  String? _token;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    // Remove qualquer cache de URL antiga de localhost / emulador
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null &&
        (savedUrl.contains('localhost') ||
            savedUrl.contains('127.0.0.1') ||
            savedUrl.contains('10.0.2.2'))) {
      await prefs.remove('api_base_url');
    }

    // Força uso da URL oficial em nuvem do Render
    _baseUrl = AppConstants.defaultApiBaseUrl;
    debugPrint('[ApiClient] API Base URL configurada para: $_baseUrl');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  String? get token => _token;

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] GET $uri');
    return await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> post(String path, dynamic body) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] POST $uri');
    return await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] PATCH $uri');
    return await http
        .patch(
          uri,
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] DELETE $uri');
    return await http
        .delete(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));
  }
}
