import 'package:defsystem/services/report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Report State ──────────────────────────────────────────
class ReportState {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> deliveryRecords;
  final List<Map<String, dynamic>> riderPerformance;
  final List<Map<String, dynamic>> deliveriesPerDay;
  final Map<String, int> statusBreakdown;

  /// All issues combined
  final List<Map<String, dynamic>> issues;

  /// issue_type == 'customer'
  final List<Map<String, dynamic>> customerIssues;

  /// issue_type == 'rider_completed'
  final List<Map<String, dynamic>> riderCompletedIssues;

  /// issue_type == 'rider_cancelled'
  final List<Map<String, dynamic>> riderCancelledIssues;

  final Map<String, int> ridersSummary;

  final DateTime? startDate;
  final DateTime? endDate;

  final bool isLoading;
  final String? error;

  const ReportState({
    this.summary = const {},
    this.deliveryRecords = const [],
    this.riderPerformance = const [],
    this.deliveriesPerDay = const [],
    this.statusBreakdown = const {},
    this.issues = const [],
    this.customerIssues = const [],
    this.riderCompletedIssues = const [],
    this.riderCancelledIssues = const [],
    this.ridersSummary = const {},
    this.startDate,
    this.endDate,
    this.isLoading = false,
    this.error,
  });

  /// Convenience: all rider issues (completed + cancelled)
  List<Map<String, dynamic>> get riderIssues => [
        ...riderCompletedIssues,
        ...riderCancelledIssues,
      ];

  /// Convenience: count of resolved issues across all types
  int get resolvedCount =>
      issues.where((e) => e['resolvedflag'] == true).length;

  ReportState copyWith({
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? deliveryRecords,
    List<Map<String, dynamic>>? riderPerformance,
    List<Map<String, dynamic>>? deliveriesPerDay,
    Map<String, int>? statusBreakdown,
    List<Map<String, dynamic>>? issues,
    List<Map<String, dynamic>>? customerIssues,
    List<Map<String, dynamic>>? riderCompletedIssues,
    List<Map<String, dynamic>>? riderCancelledIssues,
    Map<String, int>? ridersSummary,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? error,
  }) {
    return ReportState(
      summary: summary ?? this.summary,
      deliveryRecords: deliveryRecords ?? this.deliveryRecords,
      riderPerformance: riderPerformance ?? this.riderPerformance,
      deliveriesPerDay: deliveriesPerDay ?? this.deliveriesPerDay,
      statusBreakdown: statusBreakdown ?? this.statusBreakdown,
      issues: issues ?? this.issues,
      customerIssues: customerIssues ?? this.customerIssues,
      riderCompletedIssues:
          riderCompletedIssues ?? this.riderCompletedIssues,
      riderCancelledIssues:
          riderCancelledIssues ?? this.riderCancelledIssues,
      ridersSummary: ridersSummary ?? this.ridersSummary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────
List<Map<String, dynamic>> _filterByType(
  List<Map<String, dynamic>> issues,
  String type,
) =>
    issues.where((e) => e['issue_type'] == type).toList();

ReportState _applyIssues(
  ReportState state,
  List<Map<String, dynamic>> issues,
) {
  return state.copyWith(
    issues: issues,
    customerIssues: _filterByType(issues, 'customer'),
    riderCompletedIssues: _filterByType(issues, 'rider_completed'),
    riderCancelledIssues: _filterByType(issues, 'rider_cancelled'),
  );
}

// ─── Report Notifier ───────────────────────────────────────
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _reportService;

  ReportNotifier(this._reportService) : super(const ReportState());

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void clearDateRange() {
    state = const ReportState();
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _reportService.getDeliverySummary(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getDeliveryRecords(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getRiderPerformance(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getDeliveriesPerDay(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getStatusBreakdown(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getAllIssues(
          startDate: state.startDate,
          endDate: state.endDate,
        ),
        _reportService.getRidersSummary(),
      ]);

      final issues = results[5] as List<Map<String, dynamic>>;

      state = _applyIssues(
        state.copyWith(
          isLoading: false,
          summary: results[0] as Map<String, dynamic>,
          deliveryRecords: results[1] as List<Map<String, dynamic>>,
          riderPerformance: results[2] as List<Map<String, dynamic>>,
          deliveriesPerDay: results[3] as List<Map<String, dynamic>>,
          statusBreakdown: results[4] as Map<String, int>,
          ridersSummary: results[6] as Map<String, int>,
        ),
        issues,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadIssues() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final issues = await _reportService.getAllIssues(
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = _applyIssues(
        state.copyWith(isLoading: false),
        issues,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ─── Providers ─────────────────────────────────────────────
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(ref.read(reportServiceProvider));
});