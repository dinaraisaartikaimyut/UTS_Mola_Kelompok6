
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String _hashPassword(String password, String salt) {
    return sha256.convert(
      utf8.encode('$salt:$password'),
    ).toString();
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final existingEmail = prefs.getString('registeredEmail');

    if (existingEmail != null) {
      if (existingEmail.toLowerCase() == email.toLowerCase()) {
        return false;
      }
    }

    final random = Random.secure();
    final salt = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    await prefs.setString('registeredName', name);
    await prefs.setString('registeredEmail', email.trim());
    await prefs.setString('passwordSalt', salt);
    await prefs.setString(
      'passwordHash',
      _hashPassword(password, salt),
    );

    return true;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final registeredEmail = prefs.getString('registeredEmail');
    final salt = prefs.getString('passwordSalt');
    final savedHash = prefs.getString('passwordHash');

    if (registeredEmail == null || salt == null || savedHash == null) {
      return false;
    }

    if (registeredEmail.toLowerCase() != email.trim().toLowerCase()) {
      return false;
    }

    if (_hashPassword(password, salt) != savedHash) {
      return false;
    }

    await prefs.setBool('isLoggedIn', true);

    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', false);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('registeredEmail');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('registeredName');
  }
}
