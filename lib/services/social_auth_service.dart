import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';

/// Handles Google and Apple OAuth flows.
/// Falls back to mock mode when Firebase is not configured.
class SocialAuthService {
  static const _storage = FlutterSecureStorage();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ─── Google ────────────────────────────────────────────

  Future<User> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google sign-in was cancelled.');

      final user = User(
        id: account.id,
        fullName: account.displayName ?? 'Google User',
        email: account.email,
        avatarUrl: account.photoUrl,
        authMethod: 'google',
      );

      await _persistUser(user);
      return user;
    } catch (e) {
      // If no Firebase / google-services.json → use mock
      if (e.toString().contains('ApiException') ||
          e.toString().contains('sign_in_failed') ||
          e.toString().contains('MissingPluginException')) {
        return _mockSocialUser('Google');
      }
      rethrow;
    }
  }

  // ─── Apple ─────────────────────────────────────────────

  Future<User> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      // Apple sign-in only on Apple platforms — use mock on Android/Linux
      return _mockSocialUser('Apple');
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

      await _persistUser(user);
      return user;
    } catch (e) {
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('not available')) {
        return _mockSocialUser('Apple');
      }
      rethrow;
    }
  }

  // ─── Helpers ────────────────────────────────────────────

  Future<User> _mockSocialUser(String provider) async {
    debugPrint('[$provider] Mock sign-in — Firebase not configured. Using demo user.');
    final user = User(
      id: 'mock_${provider.toLowerCase()}_001',
      fullName: 'Demo ${provider} User',
      email: 'demo@sophix.app',
      avatarUrl: null,
      authMethod: provider.toLowerCase(),
    );
    await _persistUser(user);
    return user;
  }

  Future<void> _persistUser(User user) async {
    await _storage.write(key: 'auth_token', value: 'social_auth_${user.id}');
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
