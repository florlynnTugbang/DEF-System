import 'package:defsystem/services/rider_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Rider State ───────────────────────────────────────────
class RiderState {
  final List<Map<String, dynamic>> riders;
  final List<Map<String, dynamic>> availableRiders;
  final Map<String, dynamic>? selectedRider;
  final Map<String, dynamic>? activeDelivery;
  final List<Map<String, dynamic>> deliveryHistory;
  final bool isLoading;
  final String? error;

  const RiderState({
    this.riders = const [],
    this.availableRiders = const [],
    this.selectedRider,
    this.activeDelivery,
    this.deliveryHistory = const [],
    this.isLoading = false,
    this.error,
  });

  RiderState copyWith({
    List<Map<String, dynamic>>? riders,
    List<Map<String, dynamic>>? availableRiders,
    Map<String, dynamic>? selectedRider,
    Map<String, dynamic>? activeDelivery,
    List<Map<String, dynamic>>? deliveryHistory,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedRider = false,
    bool clearActiveDelivery = false,
  }) {
    return RiderState(
      riders: riders ?? this.riders,
      availableRiders: availableRiders ?? this.availableRiders,
      selectedRider:
      clearSelectedRider ? null : selectedRider ?? this.selectedRider,
      activeDelivery:
      clearActiveDelivery ? null : activeDelivery ?? this.activeDelivery,
      deliveryHistory: deliveryHistory ?? this.deliveryHistory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Rider Notifier ────────────────────────────────────────
class RiderNotifier extends StateNotifier<RiderState> {
  final RiderService _riderService;

  RiderNotifier(this._riderService) : super(const RiderState());

  // ─── Load All Riders ─────────────────────────────────────
  Future<void> loadRiders() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final riders = await _riderService.getAllRiders();

      state = state.copyWith(
        isLoading: false,
        riders: riders,
      );
    } catch (e) {
      debugPrint('LOAD RIDERS ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ─── Load Available Riders ───────────────────────────────
  Future<void> loadAvailableRiders() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final riders = await _riderService.getAvailableRiders();

      state = state.copyWith(
        isLoading: false,
        availableRiders: riders,
      );
    } catch (e) {
      debugPrint('LOAD AVAILABLE RIDERS ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ─── Load Rider Active Delivery ──────────────────────────
  Future<void> loadActiveDelivery(String riderID) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final delivery = await _riderService.getRiderActiveDelivery(riderID);

      if (delivery == null) {
        state = state.copyWith(
          isLoading: false,
          clearActiveDelivery: true,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        activeDelivery: delivery,
      );
    } catch (e) {
      debugPrint('LOAD ACTIVE DELIVERY ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearActiveDelivery: true,
      );
    }
  }

  // ─── Load Rider History ──────────────────────────────────
  Future<void> loadRiderHistory(String riderID) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final history = await _riderService.getRiderHistory(riderID);

      state = state.copyWith(
        isLoading: false,
        deliveryHistory: history,
      );
    } catch (e) {
      debugPrint('LOAD RIDER HISTORY ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ─── Mark Delivery In-Transit ────────────────────────────
  Future<bool> markInTransit({
    required String requestID,
    required String assignmentID,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _riderService.markInTransit(
        requestID: requestID,
        assignmentID: assignmentID,
      );

      state = state.copyWith(
        isLoading: false,
      );

      return true;
    } catch (e) {
      debugPrint('MARK IN TRANSIT ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  // ─── Clear Active Delivery Immediately ───────────────────
  void clearActiveDelivery() {
    state = state.copyWith(
      clearActiveDelivery: true,
    );
  }

  // ─── Clear Error ─────────────────────────────────────────
  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  // ─── Reset Rider State ───────────────────────────────────
  void reset() {
    state = const RiderState();
  }
}

// ─── Providers ─────────────────────────────────────────────
final riderServiceProvider = Provider<RiderService>((ref) {
  return RiderService();
});

final riderProvider = StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  return RiderNotifier(ref.read(riderServiceProvider));
});