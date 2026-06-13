import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.name,
    required this.email,
    required this.token,
  });

  final String name;
  final String email;
  final String token;
}

class SessionStorage {
  SessionStorage(this._preferences);

  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _tokenKey = 'auth_token';

  final SharedPreferences _preferences;

  Future<void> save(AuthSession session) async {
    await _preferences.setString(_nameKey, session.name);
    await _preferences.setString(_emailKey, session.email);
    await _preferences.setString(_tokenKey, session.token);
  }

  Future<AuthSession?> read() async {
    final name = _preferences.getString(_nameKey);
    final email = _preferences.getString(_emailKey);
    final token = _preferences.getString(_tokenKey);

    if (name == null || email == null || token == null) {
      return null;
    }

    return AuthSession(name: name, email: email, token: token);
  }

  Future<void> clear() async {
    await _preferences.remove(_nameKey);
    await _preferences.remove(_emailKey);
    await _preferences.remove(_tokenKey);
  }
}
