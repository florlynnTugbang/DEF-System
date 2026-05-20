import 'package:defsystem/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Get Delivery Summary ──────────────────────
  Future<Map<String, dynamic>> getDeliverySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('statusid, requestdatetime')
          .gte(
        'requestdatetime',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'requestdatetime',
        endDate?.toIso8601String() ?? '2100-12-31',
      );

      final list = List<Map<String, dynamic>>.from(response);

      return {
        'total': list.length,
        'pending': list.where((e) => e['statusid'] == 1).length,
        'assigned': list.where((e) => e['statusid'] == 2).length,
        'inTransit': list.where((e) => e['statusid'] == 3).length,
        'completed': list.where((e) => e['statusid'] == 4).length,
        'issueReported': list.where((e) => e['statusid'] == 5).length,
        'cancelled': list.where((e) => e['statusid'] == 6).length,
        'completionrate': list.isEmpty
            ? '0.0'
            : (list.where((e) => e['statusid'] == 4).length /
            list.length *
            100)
            .toStringAsFixed(1),
      };
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Delivery Records ──────────────────────
  Future<List<Map<String, dynamic>>> getDeliveryRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
          .gte(
        'requestdatetime',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'requestdatetime',
        endDate?.toIso8601String() ?? '2100-12-31',
      )
          .order('requestdatetime', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Rider Performance ─────────────────────
  Future<List<Map<String, dynamic>>> getRiderPerformance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryAssignmentTable)
          .select('''
            *,
            rider:staff_profiles!delivery_assignment_rider_id_fkey(
              id,
              first_name,
              middle_name,
              last_name,
              contact_number,
              vehicle_details
            )
          ''')
          .gte(
        'assignmentdatetime',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'assignmentdatetime',
        endDate?.toIso8601String() ?? '2100-12-31',
      );

      final list = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> riderMap = {};

      for (final assignment in list) {
        final rider = assignment['rider'];
        if (rider == null) continue;

        final riderID = rider['id']?.toString() ?? '';
        if (riderID.isEmpty) continue;

        final fullName = [
          rider['first_name'],
          rider['middle_name'],
          rider['last_name'],
        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

        if (!riderMap.containsKey(riderID)) {
          riderMap[riderID] = {
            'riderid': riderID,
            'name': fullName.isEmpty ? 'Unnamed Rider' : fullName,
            'contactnumber': rider['contact_number'] ?? 'N/A',
            'vehicledetails': rider['vehicle_details'] ?? 'N/A',
            'total': 0,
            'completed': 0,
            'inTransit': 0,
            'issues': 0,
          };
        }

        riderMap[riderID]!['total'] =
            (riderMap[riderID]!['total'] as int) + 1;

        if (assignment['assignmentstatus'] == 'Completed') {
          riderMap[riderID]!['completed'] =
              (riderMap[riderID]!['completed'] as int) + 1;
        }

        if (assignment['assignmentstatus'] == 'In-Transit') {
          riderMap[riderID]!['inTransit'] =
              (riderMap[riderID]!['inTransit'] as int) + 1;
        }
      }

      for (final riderID in riderMap.keys) {
        final issuesResponse = await _supabase
            .from(SupabaseConstants.deliveryIssueTable)
            .select('issueid')
            .eq('rider_id', riderID)
            .inFilter('issue_type', ['rider_completed', 'rider_cancelled']);

        riderMap[riderID]!['issues'] =
            List<Map<String, dynamic>>.from(issuesResponse).length;
      }

      return riderMap.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Deliveries Per Day ────────────────────
  Future<List<Map<String, dynamic>>> getDeliveriesPerDay({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('requestdatetime, statusid')
          .gte(
        'requestdatetime',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'requestdatetime',
        endDate?.toIso8601String() ?? '2100-12-31',
      )
          .order('requestdatetime', ascending: true);

      final list = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> dateMap = {};

      for (final item in list) {
        final date = DateTime.parse(item['requestdatetime'])
            .toLocal()
            .toString()
            .split(' ')[0];

        if (!dateMap.containsKey(date)) {
          dateMap[date] = {
            'date': date,
            'total': 0,
            'completed': 0,
          };
        }

        dateMap[date]!['total'] = (dateMap[date]!['total'] as int) + 1;

        if (item['statusid'] == 4) {
          dateMap[date]!['completed'] =
              (dateMap[date]!['completed'] as int) + 1;
        }
      }

      return dateMap.values.toList();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Status Breakdown ──────────────────────
  Future<Map<String, int>> getStatusBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.deliveryRequestTable)
          .select('statusid')
          .gte(
        'requestdatetime',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'requestdatetime',
        endDate?.toIso8601String() ?? '2100-12-31',
      );

      final list = List<Map<String, dynamic>>.from(response);

      return {
        'Pending': list.where((e) => e['statusid'] == 1).length,
        'Assigned': list.where((e) => e['statusid'] == 2).length,
        'In-Transit': list.where((e) => e['statusid'] == 3).length,
        'Completed': list.where((e) => e['statusid'] == 4).length,
        'Issue Reported': list.where((e) => e['statusid'] == 5).length,
        'Cancelled': list.where((e) => e['statusid'] == 6).length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get All Issues ────────────────────────────
  Future<List<Map<String, dynamic>>> getAllIssues({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
          rider:staff_profiles!delivery_issue_rider_id_fkey(
            id,
            first_name,
            middle_name,
            last_name,
            contact_number,
            vehicle_details
          ),
          dispatcher:staff_profiles!delivery_issue_dispatcher_id_fkey(
            id,
            first_name,
            middle_name,
            last_name,
            contact_number
          )
        ''')
          .gte(
        'datetimereported',
        startDate?.toIso8601String() ?? '2000-01-01',
      )
          .lte(
        'datetimereported',
        endDate?.toIso8601String() ?? '2100-12-31',
      )
          .order('datetimereported', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Get Riders Summary ────────────────────────
  Future<Map<String, int>> getRidersSummary() async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.staffProfilesTable)
          .select('availability_status')
          .eq('role', 'rider')
          .eq('is_active', true);

      final list = List<Map<String, dynamic>>.from(response);

      return {
        'total': list.length,
        'available':
        list.where((e) => e['availability_status'] == true).length,
        'onDelivery':
        list.where((e) => e['availability_status'] == false).length,
      };
    } catch (e) {
      rethrow;
    }
  }
}