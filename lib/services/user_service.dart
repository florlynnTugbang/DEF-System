import 'package:defsystem/core/constants/supabase_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Get All Staff Profiles ─────────────────────────────
  Future<List<Map<String, dynamic>>> getAllStaffProfiles() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .order('role', ascending: true)
          .order('first_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET STAFF PROFILES ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Staff By Role ──────────────────────────────────
  Future<List<Map<String, dynamic>>> getStaffByRole(String role) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('role', role)
          .order('first_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET STAFF BY ROLE ERROR: $e');
      rethrow;
    }
  }

  // ─── Add Staff Profile ──────────────────────────────────
  //
  // Important:
  // This only creates the staff profile row.
  // The Supabase Auth account must already exist first.
  Future<void> addStaffProfile({
    required String authUserId,
    required String role,
    required String firstName,
    required String? middleName,
    required String lastName,
    required String? contactNumber,
    required String? vehicleDetails,
    required bool? availabilityStatus,
  }) async {
    try {
      await _supabase.from(SupabaseConstants.staffProfilesTable).insert({
        'id': authUserId,
        'role': role,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'contact_number': contactNumber,
        'vehicle_details': role == 'rider' ? vehicleDetails : null,
        'availability_status': role == 'rider' ? availabilityStatus ?? true : null,
        'is_active': true,
      });

      debugPrint('Staff profile added successfully');
    } catch (e) {
      debugPrint('ADD STAFF PROFILE ERROR: $e');
      rethrow;
    }
  }

  // ─── Update Staff Profile ───────────────────────────────
  Future<void> updateStaffProfile({
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
    try {
      await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .update({
        'role': role,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'contact_number': contactNumber,
        'vehicle_details': role == 'rider' ? vehicleDetails : null,
        'availability_status':
        role == 'rider' ? availabilityStatus ?? true : null,
        'is_active': isActive,
      })
          .eq('id', id);

      debugPrint('Staff profile updated successfully');
    } catch (e) {
      debugPrint('UPDATE STAFF PROFILE ERROR: $e');
      rethrow;
    }
  }

  // ─── Activate / Deactivate Staff ────────────────────────
  Future<void> setStaffActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    try {
      await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .update({'is_active': isActive})
          .eq('id', id);

      debugPrint('Staff active status updated successfully');
    } catch (e) {
      debugPrint('SET STAFF ACTIVE STATUS ERROR: $e');
      rethrow;
    }
  }

  // ─── Delete Staff Profile ───────────────────────────────
  //
  // This deletes only the profile row, not the Supabase Auth account.
  // For demo/presentation, prefer deactivate instead of delete.
  Future<void> deleteStaffProfile(String id) async {
    try {
      await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .delete()
          .eq('id', id);

      debugPrint('Staff profile deleted successfully');
    } catch (e) {
      debugPrint('DELETE STAFF PROFILE ERROR: $e');
      rethrow;
    }
  }
}