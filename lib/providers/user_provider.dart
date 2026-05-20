import 'package:defsystem/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── User State ────────────────────────────────────────────
class UserState {
  final List<Map<String, dynamic>> staff;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const UserState({
    this.staff = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  List<Map<String, dynamic>> get admins =>
      staff.where((user) => user['role'] == 'admin').toList();

  List<Map<String, dynamic>> get dispatchers =>
      staff.where((user) => user['role'] == 'dispatcher').toList();

  List<Map<String, dynamic>> get riders =>
      staff.where((user) => user['role'] == 'rider').toList();

  UserState copyWith({
    List<Map<String, dynamic>>? staff,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      successMessage:
      clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

// ─── User Notifier ─────────────────────────────────────────
class UserNotifier extends StateNotifier<UserState> {
  final UserService _userService;

  UserNotifier(this._userService) : super(const UserState());

  // Load all staff profiles
  Future<void> loadAll() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final staff = await _userService.getAllStaffProfiles();

      state = state.copyWith(
        isLoading: false,
        staff: staff,
      );
    } catch (e) {
      debugPrint('LOAD STAFF ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load staff profiles.',
      );
    }
  }

  // Add staff profile
  Future<bool> addStaffProfile({
    required String authUserId,
    required String role,
    required String firstName,
    required String? middleName,
    required String lastName,
    required String? contactNumber,
    required String? vehicleDetails,
    required bool? availabilityStatus,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _userService.addStaffProfile(
        authUserId: authUserId,
        role: role,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        contactNumber: contactNumber,
        vehicleDetails: vehicleDetails,
        availabilityStatus: availabilityStatus,
      );

      await loadAll();

      state = state.copyWith(
        successMessage: 'Staff profile added successfully.',
      );

      return true;
    } catch (e) {
      debugPrint('ADD STAFF PROFILE ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error:
        'Failed to add staff profile. Make sure the Auth User ID exists and is not already used.',
      );

      return false;
    }
  }

  // Update staff profile
  Future<bool> updateStaffProfile({
    required String id,
    required String role,
    required String firstName,
    required String? middleName,
    required String lastName,
    required String? contactNumber,
    required String? vehicleDetails,
    required bool? availabilityStatus,
    required bool isActive,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _userService.updateStaffProfile(
        id: id,
        role: role,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        contactNumber: contactNumber,
        vehicleDetails: vehicleDetails,
        availabilityStatus: availabilityStatus,
        isActive: isActive,
      );

      await loadAll();

      state = state.copyWith(
        successMessage: 'Staff profile updated successfully.',
      );

      return true;
    } catch (e) {
      debugPrint('UPDATE STAFF PROFILE ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update staff profile.',
      );

      return false;
    }
  }

  // Activate / deactivate staff
  Future<bool> setStaffActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _userService.setStaffActiveStatus(
        id: id,
        isActive: isActive,
      );

      await loadAll();

      state = state.copyWith(
        successMessage:
        isActive ? 'Staff account activated.' : 'Staff account deactivated.',
      );

      return true;
    } catch (e) {
      debugPrint('SET STAFF ACTIVE STATUS ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update staff account status.',
      );

      return false;
    }
  }

  // Delete staff profile
  Future<bool> deleteStaffProfile(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _userService.deleteStaffProfile(id);
      await loadAll();

      state = state.copyWith(
        successMessage: 'Staff profile deleted.',
      );

      return true;
    } catch (e) {
      debugPrint('DELETE STAFF PROFILE ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete staff profile.',
      );

      return false;
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
    );
  }
}

// ─── Providers ─────────────────────────────────────────────
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(userServiceProvider));
});