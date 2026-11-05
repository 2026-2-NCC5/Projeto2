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
  String? _savedRa;
  String? _savedPwd;
  bool _isReauthenticating = false;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _savedRa = prefs.getString('saved_ra');
    _savedPwd = prefs.getString('saved_pwd');

    String defaultUrl;
    if (AppConstants.defaultApiBaseUrl.startsWith('https://')) {
      defaultUrl = AppConstants.defaultApiBaseUrl;
    } else if (kIsWeb) {
      defaultUrl = 'http://localhost:8000/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      defaultUrl = 'http://10.0.2.2:8000/api/v1';
    } else {
      defaultUrl = 'http://127.0.0.1:8000/api/v1';
    }

    _baseUrl = prefs.getString('api_base_url') ?? defaultUrl;
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

  Future<void> setSavedCredentials(String? ra, String? pwd) async {
    _savedRa = ra;
    _savedPwd = pwd;
    final prefs = await SharedPreferences.getInstance();
    if (ra != null && pwd != null) {
      await prefs.setString('saved_ra', ra);
      await prefs.setString('saved_pwd', pwd);
    } else {
      await prefs.remove('saved_ra');
      await prefs.remove('saved_pwd');
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

  Future<bool> _tryReauthenticate() async {
    if (_isReauthenticating) return false;
    _isReauthenticating = true;
    try {
      final ra = _savedRa ?? '123456';
      final pwd = _savedPwd ?? 'senha123';
      final uri = Uri.parse('$_baseUrl/auth/login');
      debugPrint('[ApiClient] Tentando autenticação automática com $ra...');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'ra_or_email': ra, 'password': pwd}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final newToken = data['access_token'];
        await setToken(newToken);
        debugPrint('[ApiClient] Autenticação automática bem-sucedida! Novo token obtido.');
        return true;
      }
    } catch (e) {
      debugPrint('[ApiClient] Falha na autenticação automática: $e');
    } finally {
      _isReauthenticating = false;
    }
    return false;
  }

  Future<http.Response> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] GET $uri');
    if (_token == null && !path.startsWith('/auth') && !_isReauthenticating) {
      await _tryReauthenticate();
    }
    var response = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !path.startsWith('/auth') && !_isReauthenticating) {
      final success = await _tryReauthenticate();
      if (success) {
        response = await http
            .get(uri, headers: _headers())
            .timeout(const Duration(seconds: 60));
      }
    }
    return response;
  }

  Future<http.Response> post(String path, dynamic body) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] POST $uri');
    if (_token == null && !path.startsWith('/auth') && !_isReauthenticating) {
      await _tryReauthenticate();
    }
    var response = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !path.startsWith('/auth') && !_isReauthenticating) {
      final success = await _tryReauthenticate();
      if (success) {
        response = await http
            .post(
              uri,
              headers: _headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 60));
      }
    }
    return response;
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] PATCH $uri');
    if (_token == null && !path.startsWith('/auth') && !_isReauthenticating) {
      await _tryReauthenticate();
    }
    var response = await http
        .patch(
          uri,
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !path.startsWith('/auth') && !_isReauthenticating) {
      final success = await _tryReauthenticate();
      if (success) {
        response = await http
            .patch(
              uri,
              headers: _headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 60));
      }
    }
    return response;
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[ApiClient] DELETE $uri');
    if (_token == null && !path.startsWith('/auth') && !_isReauthenticating) {
      await _tryReauthenticate();
    }
    var response = await http
        .delete(uri, headers: _headers())
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 && !path.startsWith('/auth') && !_isReauthenticating) {
      final success = await _tryReauthenticate();
      if (success) {
        response = await http
            .delete(uri, headers: _headers())
            .timeout(const Duration(seconds: 60));
      }
    }
    return response;
  }
}
