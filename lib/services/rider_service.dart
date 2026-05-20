import 'package:defsystem/core/constants/supabase_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Get All Riders From staff_profiles ──────────────────
  Future<List<Map<String, dynamic>>> getAllRiders() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('role', 'rider')
          .order('first_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET ALL RIDERS ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Available Riders From staff_profiles ────────────
  Future<List<Map<String, dynamic>>> getAvailableRiders() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('role', 'rider')
          .eq('is_active', true)
          .eq('availability_status', true)
          .order('first_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET AVAILABLE RIDERS ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Single Rider From staff_profiles ─────────────────
  Future<Map<String, dynamic>> getRider(String riderID) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select()
          .eq('id', riderID)
          .eq('role', 'rider')
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('GET RIDER ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Rider Active Delivery Using RPC ──────────────────
  Future<Map<String, dynamic>?> getRiderActiveDelivery(String riderID) async {
    try {
      final response = await _supabase.rpc('get_rider_active_delivery');

      final rows = List<Map<String, dynamic>>.from(response);

      if (rows.isEmpty) return null;

      final row = rows.first;

      return {
        'assignmentid': row['assignmentid'],
        'requestid': row['requestid'],
        'rider_id': row['rider_id'],
        'dispatcher_id': row['dispatcher_id'],
        'assignmentdatetime': row['assignmentdatetime'],
        'assignmentstatus': row['assignmentstatus'],
        'completeddatetime': row['completeddatetime'],
        'delivery_request': {
          'requestid': row['requestid'],
          'statusid': row['request_statusid'],
          'requestdatetime': row['requestdatetime'],
          'pickupaddress': row['pickupaddress'],
          'deliveryaddress': row['deliveryaddress'],
          'itemdescription': row['itemdescription'],
          'specialinstructions': row['specialinstructions'],
          'delivery_status': {
            'statusid': row['request_statusid'],
            'statusname': row['request_statusname'],
          },
          'customer': {
            'customerid': row['customerid'],
            'custfname': row['customer_name'],
            'custmname': null,
            'custlname': '',
            'contactnumber': row['customer_contact'],
          },
        },
      };
    } catch (e) {
      debugPrint('GET RIDER ACTIVE DELIVERY ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Rider Delivery History ──────────────────────────
  Future<List<Map<String, dynamic>>> getRiderHistory(String riderID) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryAssignmentTable)
          .select('''
            *,
            delivery_request(
              *,
              customer(*),
              delivery_status(*)
            )
          ''')
          .eq('rider_id', riderID)
          .inFilter(
        'assignmentstatus',
        ['Completed', 'Cancelled'],
      )
          .order('assignmentdatetime', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET RIDER HISTORY ERROR: $e');
      rethrow;
    }
  }

  // ─── Update Rider Availability ───────────────────────────
  Future<void> updateAvailability({
    required String riderID,
    required bool isAvailable,
  }) async {
    try {
      await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .update({'availability_status': isAvailable})
          .eq('id', riderID)
          .eq('role', 'rider');
    } catch (e) {
      debugPrint('UPDATE RIDER AVAILABILITY ERROR: $e');
      rethrow;
    }
  }

  // ─── Mark In-Transit ─────────────────────────────────────
  Future<void> markInTransit({
    required String requestID,
    required String assignmentID,
  }) async {
    try {
      await _supabase.rpc(
        'mark_delivery_in_transit',
        params: {
          'p_request_id': requestID,
          'p_assignment_id': assignmentID,
        },
      );

      debugPrint('MARK IN TRANSIT SUCCESS');
    } catch (e) {
      debugPrint('MARK IN TRANSIT ERROR: $e');
      rethrow;
    }
  }
}