import 'package:defsystem/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Auth State ────────────────────────────────────────────
class AuthState {
  final String? role;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.role,
    this.userData,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => role != null && userData != null;

  String get displayName {
    if (userData == null) return '';

    final parts = [
      userData!['first_name'],
      userData!['middle_name'],
      userData!['last_name'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    return parts;
  }

  String get contactNumber => userData?['contact_number'] ?? '';

  String get userID => userData?['id'] ?? '';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Management';
      case 'dispatcher':
        return 'Dispatcher';
      case 'rider':
        return 'Rider';
      default:
        return '';
    }
  }

  AuthState copyWith({
    String? role,
    Map<String, dynamic>? userData,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearAuth = false,
  }) {
    if (clearAuth) {
      return const AuthState();
    }

    return AuthState(
      role: role ?? this.role,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Auth Notifier ─────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      state = AuthState(
        isLoading: false,
        role: result['role'],
        userData: result['data'],
      );
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadCurrentUser() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _authService.getCurrentStaffProfile();

      if (profile == null) {
        state = const AuthState();
        return;
      }

      state = AuthState(
        isLoading: false,
        role: profile['role'],
        userData: profile,
      );
    } catch (e) {
      debugPrint('LOAD CURRENT USER ERROR: $e');
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> updateProfile({
    required String fname,
    required String? mname,
    required String lname,
    required String? contactNumber,
    String? vehicleDetails,
    bool? availabilityStatus,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _authService.updateProfile(
        id: state.userID,
        fname: fname,
        mname: mname,
        lname: lname,
        contactNumber: contactNumber,
        vehicleDetails: vehicleDetails,
        availabilityStatus: availabilityStatus,
      );

      state = state.copyWith(
        isLoading: false,
        userData: updated,
      );

      return true;
    } catch (e) {
      debugPrint('UPDATE PROFILE ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }
}

// ─── Providers ─────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});