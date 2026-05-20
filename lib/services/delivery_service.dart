import 'package:defsystem/core/constants/supabase_constants.dart';
import 'package:defsystem/models/delivery_request_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Create Delivery Request Through Public RPC ───────────
  Future<DeliveryRequestModel> createRequest({
    required String custFname,
    required String? custMname,
    required String custLname,
    required String contactNumber,
    required String? email,
    required String pickupAddress,
    required String deliveryAddress,
    required String? itemDescription,
    required String? specialInstructions,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_public_delivery_request',
        params: {
          'p_custfname': custFname.trim(),
          'p_custmname': custMname?.trim() ?? '',
          'p_custlname': custLname.trim(),
          'p_contactnumber': contactNumber.trim(),
          'p_email': email?.trim() ?? '',
          'p_pickupaddress': pickupAddress.trim(),
          'p_deliveryaddress': deliveryAddress.trim(),
          'p_itemdescription': itemDescription?.trim() ?? '',
          'p_specialinstructions': specialInstructions?.trim() ?? '',
        },
      );

      final rows = List<Map<String, dynamic>>.from(response);

      if (rows.isEmpty) {
        throw Exception('Failed to create delivery request.');
      }

      final row = rows.first;

      final converted = {
        'requestid': row['requestid'],
        'customerid': row['customerid'],
        'dispatcherid': null,
        'statusid': row['statusid'],
        'requestdatetime': row['requestdatetime'],
        'pickupaddress': row['pickupaddress'],
        'deliveryaddress': row['deliveryaddress'],
        'itemdescription': row['itemdescription'],
        'specialinstructions': row['specialinstructions'],
        'customer': {
          'customerid': row['customerid'],
          'custfname': row['custfname'],
          'custmname': row['custmname'],
          'custlname': row['custlname'],
          'contactnumber': row['contactnumber'],
          'email': row['email'],
        },
        'delivery_status': {
          'statusid': row['statusid'],
          'statusname': row['statusname'] ?? 'Pending',
        },
        'delivery_assignment': null,
      };

      return DeliveryRequestModel.fromJson(converted);
    } catch (e) {
      debugPrint('CREATE DELIVERY REQUEST ERROR: $e');
      rethrow;
    }
  }

  // ─── Get All Requests ────────────────────────────────────
  Future<List<DeliveryRequestModel>> getAllRequests() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('''
            *,
            customer(*),
            delivery_status(*),
            dispatcher:staff_profiles!delivery_request_dispatcher_id_fkey(*),
            delivery_assignment(
              *,
              rider:staff_profiles!delivery_assignment_rider_id_fkey(*),
              dispatcher:staff_profiles!delivery_assignment_dispatcher_id_fkey(*)
            )
          ''')
          .order('requestdatetime', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((e) => DeliveryRequestModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('GET ALL REQUESTS ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Single Request ──────────────────────────────────
  Future<DeliveryRequestModel> getRequest(String requestID) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('''
            *,
            customer(*),
            delivery_status(*),
            dispatcher:staff_profiles!delivery_request_dispatcher_id_fkey(*),
            delivery_assignment(
              *,
              rider:staff_profiles!delivery_assignment_rider_id_fkey(*),
              dispatcher:staff_profiles!delivery_assignment_dispatcher_id_fkey(*)
            )
          ''')
          .eq('requestid', requestID)
          .single();

      return DeliveryRequestModel.fromJson(response);
    } catch (e) {
      debugPrint('GET REQUEST ERROR: $e');
      rethrow;
    }
  }

  // ─── Track By Reference + Contact Number ─────────────────
  Future<DeliveryRequestModel?> trackRequest({
    required String requestID,
    required String contactNumber,
  }) async {
    try {
      final response = await _supabase.rpc(
        'track_delivery_public',
        params: {
          'p_request_id': requestID.trim(),
          'p_contact_number': contactNumber.trim(),
        },
      );

      final rows = List<Map<String, dynamic>>.from(response);

      if (rows.isEmpty) return null;

      final row = rows.first;

      final converted = {
        'requestid': row['requestid'],
        'statusid': row['statusid'],
        'requestdatetime': row['requestdatetime'],
        'pickupaddress': row['pickupaddress'],
        'deliveryaddress': row['deliveryaddress'],
        'itemdescription': row['itemdescription'],
        'specialinstructions': row['specialinstructions'],
        'customer': {
          'custfname': row['customer_name'],
          'custmname': null,
          'custlname': '',
          'contactnumber': row['customer_contact'],
        },
        'delivery_status': {
          'statusid': row['statusid'],
          'statusname': row['statusname'],
        },
        'delivery_assignment': row['rider_name'] == null
            ? null
            : {
          'rider': {
            'first_name': row['rider_name'],
            'middle_name': null,
            'last_name': '',
            'contact_number': row['rider_contact'],
            'vehicle_details': row['rider_vehicle'],
          }
        },
      };

      return DeliveryRequestModel.fromJson(converted);
    } catch (e) {
      debugPrint('TRACK REQUEST ERROR: $e');
      rethrow;
    }
  }

  // ─── Assign Rider ────────────────────────────────────────
  Future<void> assignRider({
    required String requestID,
    required String riderID,
    required String dispatcherID,
  }) async {
    try {
      await _supabase.rpc(
        'assign_delivery_request',
        params: {
          'p_request_id': requestID,
          'p_rider_id': riderID,
        },
      );

      debugPrint('ASSIGN RIDER SUCCESS');
    } catch (e) {
      debugPrint('ASSIGN RIDER ERROR: $e');
      rethrow;
    }
  }

  // ─── Update Status ───────────────────────────────────────
  Future<void> updateStatus({
    required String requestID,
    required int statusID,
  }) async {
    try {
      await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .update({'statusid': statusID}).eq('requestid', requestID);
    } catch (e) {
      debugPrint('UPDATE STATUS ERROR: $e');
      rethrow;
    }
  }

  // ─── Complete Delivery ───────────────────────────────────
  Future<void> completeDelivery({
    required String requestID,
    required String riderID,
    required String assignmentID,
  }) async {
    try {
      await _supabase.rpc(
        'complete_delivery_by_rider',
        params: {
          'p_request_id': requestID,
          'p_assignment_id': assignmentID,
        },
      );

      debugPrint('COMPLETE DELIVERY SUCCESS');
    } catch (e) {
      debugPrint('COMPLETE DELIVERY ERROR: $e');
      rethrow;
    }
  }

  // ─── Complete Delivery After Issue ───────────────────────
  Future<void> completeDeliveryAfterIssue({
    required String requestID,
    required String riderID,
    required String assignmentID,
  }) async {
    try {
      await _supabase.rpc(
        'complete_delivery_by_rider',
        params: {
          'p_request_id': requestID,
          'p_assignment_id': assignmentID,
        },
      );

      debugPrint('COMPLETE DELIVERY AFTER ISSUE SUCCESS');
    } catch (e) {
      debugPrint('COMPLETE AFTER ISSUE ERROR: $e');
      rethrow;
    }
  }

  // ─── Cancel Delivery By Rider ────────────────────────────
  Future<void> cancelDelivery({
    required String requestID,
    required String riderID,
    required String assignmentID,
    String? cancellationReason,
  }) async {
    try {
      await _supabase.rpc(
        'cancel_delivery_by_rider',
        params: {
          'p_request_id': requestID,
          'p_assignment_id': assignmentID,
          'p_reason': cancellationReason?.trim() ?? '',
        },
      );

      debugPrint('CANCEL DELIVERY SUCCESS');
    } catch (e) {
      debugPrint('CANCEL DELIVERY ERROR: $e');
      rethrow;
    }
  }

  // ─── Rider Reports Issue Instead of Completing ───────────
  Future<void> reportIssue({
    required String requestID,
    required String riderID,
    required String description,
    String? assignmentID,
  }) async {
    try {
      String finalAssignmentID = assignmentID ?? '';

      if (finalAssignmentID.isEmpty) {
        final assignmentResponse = await _supabase
            .from(SupabaseConstants.deliveryAssignmentTable)
            .select('assignmentid')
            .eq('requestid', requestID)
            .eq('rider_id', riderID)
            .order('assignmentdatetime', ascending: false)
            .limit(1)
            .maybeSingle();

        finalAssignmentID =
            assignmentResponse?['assignmentid']?.toString() ?? '';
      }

      if (finalAssignmentID.isEmpty) {
        throw Exception('Assignment not found for this delivery.');
      }

      final cleanDescription = description
          .replaceAll('\u0000', '')
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
          .trim();

      if (cleanDescription.isEmpty) {
        throw Exception('Issue description is required.');
      }

      await _supabase.rpc(
        'report_rider_completed_issue',
        params: {
          'p_request_id': requestID,
          'p_assignment_id': finalAssignmentID,
          'p_description': cleanDescription,
        },
      );

      debugPrint('RIDER ISSUE REPORT SUCCESS');
    } catch (e) {
      debugPrint('REPORT ISSUE ERROR: $e');
      rethrow;
    }
  }

  // ─── Customer Report Issue ───────────────────────────────
  Future<void> reportCustomerIssue({
    required String requestID,
    required String contactNumber,
    required String description,
  }) async {
    try {
      final cleanDescription = description
          .replaceAll('\u0000', '')
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
          .trim();

      if (cleanDescription.isEmpty) {
        throw Exception('Issue description is required.');
      }

      await _supabase.rpc(
        'report_customer_issue_public',
        params: {
          'p_request_id': requestID.trim(),
          'p_contact_number': contactNumber.trim(),
          'p_description': cleanDescription,
        },
      );

      debugPrint('CUSTOMER ISSUE REPORT SUCCESS');
    } catch (e) {
      debugPrint('REPORT CUSTOMER ISSUE ERROR: $e');
      rethrow;
    }
  }

  // ─── Resolve Issue ───────────────────────────────────────
  Future<void> resolveIssue({
    required String issueID,
    required String resolvedBy,
    required String resolutionNotes,
  }) async {
    try {
      final cleanNotes = resolutionNotes
          .replaceAll('\u0000', '')
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
          .trim();

      if (cleanNotes.isEmpty) {
        throw Exception('Resolution notes are required.');
      }

      await _supabase.rpc(
        'resolve_delivery_issue',
        params: {
          'p_issue_id': issueID.trim(),
          'p_resolution_notes': cleanNotes,
        },
      );

      debugPrint('ISSUE RESOLVED SUCCESS');
    } catch (e) {
      debugPrint('RESOLVE ISSUE ERROR: $e');
      rethrow;
    }
  }

  // ─── Get All Issues ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllIssues() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryIssueTable)
          .select('''
            *,
            delivery_request(
              *,
              customer(*),
              delivery_status(*)
            ),
            rider:staff_profiles!delivery_issue_rider_id_fkey(*),
            dispatcher:staff_profiles!delivery_issue_dispatcher_id_fkey(*)
          ''')
          .order('datetimereported', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('GET ALL ISSUES ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Today's Summary ────────────────────────────────
  Future<Map<String, int>> getTodaySummary() async {
    try {
      final today = DateTime.now();
      final startOfDay =
      DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay =
      DateTime(today.year, today.month, today.day, 23, 59, 59)
          .toIso8601String();

      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('statusid')
          .gte('requestdatetime', startOfDay)
          .lte('requestdatetime', endOfDay);

      final list = List<Map<String, dynamic>>.from(response);

      return {
        'total': list.length,
        'pending': list.where((e) => e['statusid'] == 1).length,
        'assigned': list.where((e) => e['statusid'] == 2).length,
        'inTransit': list.where((e) => e['statusid'] == 3).length,
        'completed': list.where((e) => e['statusid'] == 4).length,
        'issueReported': list.where((e) => e['statusid'] == 5).length,
        'cancelled': list.where((e) => e['statusid'] == 6).length,
      };
    } catch (e) {
      debugPrint('GET SUMMARY ERROR: $e');
      rethrow;
    }
  }
}