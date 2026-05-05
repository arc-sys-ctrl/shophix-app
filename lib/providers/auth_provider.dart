import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/social_auth_service.dart';
import '../services/notification_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final socialAuthServiceProvider = Provider((ref) => SocialAuthService());

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isLoggedIn => user != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => _loadUser());
    return AuthState();
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    final authService = ref.read(authServiceProvider);
    final map = await authService.getSavedUserMap();
    if (map == null) {
      state = state.copyWith(user: null, isLoading: false);
      return;
    }
    final token = await authService.getToken();
    if (token != null) {
      try {
        final profile = await authService.fetchProfile(token);
        final merged = {...map, ...profile};
        await authService.saveUserMap(merged);
        state = state.copyWith(user: User.fromJson(merged), isLoading: false);
        return;
      } catch (_) {
        /* offline or expired — show cached user */
      }
    }
    state = state.copyWith(user: User.fromJson(map), isLoading: false);
  }

  /// Reload profile from `GET /users/me` and persist (e.g. after CRM updates name/phone).
  Future<void> refreshProfile() async {
    final authService = ref.read(authServiceProvider);
    final token = await authService.getToken();
    final map = await authService.getSavedUserMap();
    if (token == null || map == null) return;
    try {
      final profile = await authService.fetchProfile(token);
      final merged = {...map, ...profile};
      await authService.saveUserMap(merged);
      state = state.copyWith(user: User.fromJson(merged));
    } catch (_) {
      /* offline / expired — leave current user */
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email, password);
      Map<String, dynamic> userMap = Map<String, dynamic>.from(result['user'] as Map);
      if (userMap['role'] != 'admin') {
        try {
          final profile = await authService.fetchProfile(result['token'] as String);
          userMap = {...userMap, ...profile};
          await authService.saveUserMap(userMap);
        } catch (_) {
          /* profile optional */
        }
      }
      state = state.copyWith(
        user: User.fromJson(userMap),
        isLoading: false,
      );
      // Sync FCM token with backend after successful login
      NotificationService().initialize();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(fullName, email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Social Sign-In ──────────────────────────────────────

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(socialAuthServiceProvider);
      final user = await service.signInWithGoogle();
      state = state.copyWith(user: user, isLoading: false);
      // Sync FCM token with backend after successful social login
      NotificationService().initialize();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(socialAuthServiceProvider);
      final user = await service.signInWithApple();
      state = state.copyWith(user: user, isLoading: false);
      // Sync FCM token with backend after successful social login
      NotificationService().initialize();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
      return false;
    }
  }

  // ─── Logout ──────────────────────────────────────────────

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    final socialService = ref.read(socialAuthServiceProvider);
    await authService.logout();
    await socialService.signOut();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
