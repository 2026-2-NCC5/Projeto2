import 'dart:convert';
import 'package:asa_connect/models/user.dart';
import 'package:asa_connect/services/api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<UserModel> login(String raOrEmail, String password) async {
    final response = await _client.post('/auth/login', {
      'ra_or_email': raOrEmail,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final token = data['access_token'];
      await _client.setToken(token);
      return UserModel.fromJson(data['user']);
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Falha ao autenticar.');
    }
  }

  Future<UserModel> getMe() async {
    final response = await _client.get('/auth/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromJson(data);
    } else {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
  }

  Future<void> updateAccessibilityPreferences({
    String? fontSizeFactor,
    bool? highContrast,
    bool? notificationsEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (fontSizeFactor != null) body['font_size_factor'] = fontSizeFactor;
    if (highContrast != null) body['high_contrast'] = highContrast;
    if (notificationsEnabled != null) body['notifications_enabled'] = notificationsEnabled;

    await _client.patch('/profile', body);
  }

  Future<String> recoverPassword(String raOrEmail) async {
    final response = await _client.post('/auth/recover-password', {
      'ra_or_email': raOrEmail,
    });
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['message'] ?? 'Instruções enviadas.';
  }

  Future<void> logout() async {
    await _client.setToken(null);
  }
}
