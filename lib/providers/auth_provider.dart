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
    final user = await authService.getSavedUser();
    state = state.copyWith(user: user, isLoading: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email, password);
      state = state.copyWith(
        user: User.fromJson(result['user']),
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
