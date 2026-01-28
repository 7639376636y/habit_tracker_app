import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;

  AuthResult({required this.success, this.message, this.user, this.token});
}

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Sign up
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signUp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final user = User.fromJson(data['user']);
        final token = data['token'];

        await _saveAuthData(token, user);

        return AuthResult(
          success: true,
          message: 'Account created successfully',
          user: user,
          token: token,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Sign up failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Sign in
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signIn),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(data['user']);
        final token = data['token'];

        await _saveAuthData(token, user);

        return AuthResult(
          success: true,
          message: 'Login successful',
          user: user,
          token: token,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Sign in failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get current user
  Future<AuthResult> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResult(success: false, message: 'No token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);

        return AuthResult(success: true, user: user, token: token);
      } else {
        await signOut();
        return AuthResult(success: false, message: 'Session expired');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Save auth data
  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
