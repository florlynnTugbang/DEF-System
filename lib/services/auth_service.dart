import 'package:defsystem/core/constants/supabase_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Sign In Using Supabase Auth ───────────────────────
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();

      if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
        throw Exception('Please enter your email and password.');
      }

      final authResponse = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception('Login failed. Please try again.');
      }

      final profile = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (profile == null) {
        await _supabase.auth.signOut();
        throw Exception('No active staff profile found for this account.');
      }

      return {
        'role': profile['role'],
        'data': Map<String, dynamic>.from(profile),
      };
    } on AuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.message}');
      throw Exception('Invalid email or password.');
    } catch (e) {
      debugPrint('SIGN IN ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Current Staff Profile ─────────────────────────
  Future<Map<String, dynamic>?> getCurrentStaffProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) return null;

      final profile = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (profile == null) return null;

      return Map<String, dynamic>.from(profile);
    } catch (e) {
      debugPrint('GET CURRENT STAFF PROFILE ERROR: $e');
      rethrow;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── Update Profile ────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String fname,
    required String? mname,
    required String lname,
    required String? contactNumber,
    String? vehicleDetails,
    bool? availabilityStatus,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'first_name': fname.trim(),
        'middle_name': mname?.trim(),
        'last_name': lname.trim(),
        'contact_number': contactNumber?.trim(),
      };

      if (vehicleDetails != null) {
        updates['vehicle_details'] = vehicleDetails.trim();
      }

      if (availabilityStatus != null) {
        updates['availability_status'] = availabilityStatus;
      }

      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('UPDATE PROFILE ERROR: $e');
      rethrow;
    }
  }
}