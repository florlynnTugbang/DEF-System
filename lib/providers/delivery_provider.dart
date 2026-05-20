import 'package:defsystem/models/delivery_request_model.dart';
import 'package:defsystem/services/delivery_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Delivery State ────────────────────────────────────────
class DeliveryState {
  final List<DeliveryRequestModel> requests;
  final DeliveryRequestModel? selectedRequest;
  final Map<String, int> summary;
  final bool isLoading;
  final String? error;

  const DeliveryState({
    this.requests = const [],
    this.selectedRequest,
    this.summary = const {},
    this.isLoading = false,
    this.error,
  });

  DeliveryState copyWith({
    List<DeliveryRequestModel>? requests,
    DeliveryRequestModel? selectedRequest,
    bool clearSelected = false,
    Map<String, int>? summary,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DeliveryState(
      requests: requests ?? this.requests,
      selectedRequest:
      clearSelected ? null : selectedRequest ?? this.selectedRequest,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── Delivery Notifier ─────────────────────────────────────
class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryNotifier(this._deliveryService) : super(const DeliveryState());

  void clearSelectedRequest() {
    state = state.copyWith(
      clearSelected: true,
      clearError: true,
    );
  }

  Future<void> loadRequests() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final requests = await _deliveryService.getAllRequests();

      state = state.copyWith(
        isLoading: false,
        requests: requests,
      );
    } catch (e) {
      debugPrint('LOAD REQUESTS ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadRequest(String requestID) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final request = await _deliveryService.getRequest(requestID);

      state = state.copyWith(
        isLoading: false,
        selectedRequest: request,
      );
    } catch (e) {
      debugPrint('LOAD REQUEST ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<DeliveryRequestModel?> createRequest({
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
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final request = await _deliveryService.createRequest(
        custFname: custFname,
        custMname: custMname,
        custLname: custLname,
        contactNumber: contactNumber,
        email: email,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        itemDescription: itemDescription,
        specialInstructions: specialInstructions,
      );

      state = state.copyWith(isLoading: false);

      return request;
    } catch (e) {
      debugPrint('CREATE REQUEST ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  Future<DeliveryRequestModel?> trackRequest({
    required String requestID,
    required String contactNumber,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelected: true,
    );

    try {
      final request = await _deliveryService.trackRequest(
        requestID: requestID,
        contactNumber: contactNumber,
      );

      state = state.copyWith(
        isLoading: false,
        selectedRequest: request,
      );

      return request;
    } catch (e) {
      debugPrint('TRACK REQUEST ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearSelected: true,
      );

      return null;
    }
  }

  Future<void> assignRider({
    required String requestID,
    required String riderID,
    required String dispatcherID,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deliveryService.assignRider(
        requestID: requestID,
        riderID: riderID,
        dispatcherID: dispatcherID,
      );

      final requests = await _deliveryService.getAllRequests();
      final summary = await _deliveryService.getTodaySummary();

      state = state.copyWith(
        isLoading: false,
        requests: requests,
        summary: summary,
      );
    } catch (e) {
      debugPrint('ASSIGN RIDER ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> completeDelivery({
    required String requestID,
    required String riderID,
    required String assignmentID,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deliveryService.completeDelivery(
        requestID: requestID,
        riderID: riderID,
        assignmentID: assignmentID,
      );

      final requests = await _deliveryService.getAllRequests();
      final summary = await _deliveryService.getTodaySummary();

      state = state.copyWith(
        isLoading: false,
        requests: requests,
        summary: summary,
      );
    } catch (e) {
      debugPrint('COMPLETE DELIVERY ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> cancelDelivery({
    required String requestID,
    required String riderID,
    required String assignmentID,
    String? cancellationReason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deliveryService.cancelDelivery(
        requestID: requestID,
        riderID: riderID,
        assignmentID: assignmentID,
        cancellationReason: cancellationReason,
      );

      final requests = await _deliveryService.getAllRequests();
      final summary = await _deliveryService.getTodaySummary();

      state = state.copyWith(
        isLoading: false,
        requests: requests,
        summary: summary,
      );
    } catch (e) {
      debugPrint('CANCEL DELIVERY ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> reportIssue({
    required String requestID,
    required String riderID,
    required String assignmentID,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deliveryService.reportIssue(
        requestID: requestID,
        riderID: riderID,
        assignmentID: assignmentID,
        description: description,
      );

      final requests = await _deliveryService.getAllRequests();
      final summary = await _deliveryService.getTodaySummary();

      state = state.copyWith(
        isLoading: false,
        requests: requests,
        summary: summary,
      );
    } catch (e) {
      debugPrint('REPORT ISSUE ERROR: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSummary() async {
    try {
      final summary = await _deliveryService.getTodaySummary();

      state = state.copyWith(summary: summary);
    } catch (e) {
      debugPrint('LOAD SUMMARY ERROR: $e');

      state = state.copyWith(error: e.toString());
    }
  }
}

// ─── Providers ─────────────────────────────────────────────
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService();
});

final deliveryProvider =
StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  return DeliveryNotifier(ref.read(deliveryServiceProvider));
});