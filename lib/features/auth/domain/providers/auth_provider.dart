import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/auth_repository.dart';
import '../models/user_model.dart';
import 'shop_provider.dart';

export 'shop_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    const FlutterSecureStorage(),
  );
});

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _repo.apiClient.setLogoutCallback(() async {
      await _repo.clearLocalSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> checkAuth() async {
    // Android'da flutter_secure_storage ba'zan Keystore initsializatsiyasi sababli
    // birinchi o'qishda osilib qoladi — 3 sekundlik timeout xavfsizlik tarmog'i.
    String? token;
    try {
      token = await _repo
          .getSavedToken()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    _repo.apiClient.setToken(token);

    try {
      final user = await _repo.me().timeout(const Duration(seconds: 10));
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      try {
        await _repo.logout();
      } catch (_) {}
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> sendCode(String phone) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.sendCode(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<({bool phoneExists, String? debugCode})> sendCodeWithResult(
      String phone) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.sendCode(phone);
      state = state.copyWith(isLoading: false);
      return (phoneExists: result.phoneExists, debugCode: result.debugCode);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String code,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.register(
        name: name,
        phone: phone,
        code: code,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.login(phone: phone, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setAuthenticatedFromTelegram(UserModel user) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      isLoading: false,
    );
  }

  /// Serverdan kelgan yangilangan foydalanuvchi profilini holatga yozadi
  /// (masalan, Telegram bog'langandan keyin).
  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Profil ma'lumotlarini serverdan jim yangilaydi (auth statusiga tegmaydi).
  /// Ekran ochilganda eng so'nggi ma'lumotni ko'rsatish uchun ishlatiladi.
  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = state.copyWith(user: user);
    } catch (_) {
      // Jim — tarmoq xatosi profil ekranini buzmasligi kerak.
    }
  }

  /// Sign in with Apple flow:
  ///  1. Native sheet ochiladi (iOS/macOS only).
  ///  2. Identity token va ixtiyoriy ism/email backendga yuboriladi.
  ///  3. Backend tasdiqlab Sanctum token qaytaradi.
  ///
  /// Foydalanuvchi bekor qilsa `false` qaytaradi va xato chiqarmaydi.
  Future<bool> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      state = state.copyWith(error: 'apple_unsupported_platform');
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'apple_no_token',
        );
        return false;
      }

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ').trim();

      final result = await _repo.signInWithApple(
        identityToken: identityToken,
        name: fullName.isEmpty ? null : fullName,
        email: credential.email,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
      );
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
    await ref.read(shopProvider.notifier).resetOnLogout();
  }

  Future<bool> updateProfile({String? name, String? email, String? locale}) async {
    try {
      final user = await _repo.updateProfile(name: name, email: email, locale: locale);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    try {
      final user = await _repo.uploadAvatar(filePath);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAvatar() async {
    try {
      final user = await _repo.deleteAvatar();
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteAccount();
      state = const AuthState(status: AuthStatus.unauthenticated);
      await ref.read(shopProvider.notifier).resetOnLogout();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Joriy foydalanuvchi xodim (seller) ekanligi — har bir API javobidagi
/// `user_type` asosida. Auth user'da bo'lmasa tanlangan do'kon rolidan olinadi.
final isSellerProvider = Provider<bool>((ref) {
  final userType = ref.watch(authProvider.select((s) => s.user?.userType));
  if (userType != null) return userType == 'seller';

  final shopType = ref.watch(shopProvider.select((s) => s.selected?.userType));
  return shopType == 'seller';
});

/// Joriy foydalanuvchi biznes egasi (owner) ekanligi.
final isOwnerProvider = Provider<bool>((ref) => !ref.watch(isSellerProvider));
