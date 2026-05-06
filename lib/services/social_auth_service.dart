import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/env_config.dart';

/// Handles Google and Apple OAuth flows against the backend API.
class SocialAuthService {
  static const _storage = FlutterSecureStorage();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ─── Google ────────────────────────────────────────────

  Future<User> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in was cancelled.');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.trim().isEmpty) {
      throw Exception('Google sign-in failed: missing ID token.');
    }

    final response = await http.post(
      Uri.parse('${EnvConfig.authUrl}/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Google backend login failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _storage.write(key: 'token', value: data['token']?.toString() ?? '');
    await _storage.write(key: 'user', value: jsonEncode(data['user']));

    final user = User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    return user;
  }

  // ─── Apple ─────────────────────────────────────────────

  Future<User> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple sign-in is only available on Apple platforms.');
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final user = User(
        id: credential.userIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName.isNotEmpty ? fullName : 'Apple User',
        email: credential.email ?? '',
        avatarUrl: null,
        authMethod: 'apple',
      );

      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
