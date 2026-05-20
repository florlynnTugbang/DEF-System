/// Represents a delivery issue in the system.
///
/// issue_type values:
///   'customer'         — reported by a customer (resolved by dispatcher OR management)
///   'rider_completed'  — rider reported issue but delivery was completed (resolved by management)
///   'rider_cancelled'  — rider reported issue and delivery was cancelled (resolved by dispatcher)
///
/// issueid prefixes:
///   CISS1001  — customer issues
///   RISS1001  — rider issues on completed deliveries
///   RCSS1001  — rider issues on cancelled deliveries
class DeliveryIssueModel {
  final String issueID;
  final String requestID;
  final String riderID;
  final String? dispatcherID;
  final String issueType; // 'customer' | 'rider_completed' | 'rider_cancelled'
  final String? description;
  final DateTime dateTimeReported;
  final bool resolvedFlag;
  final DateTime? resolvedDateTime;
  final String? resolvedBy;     // user id of resolver
  final String? resolutionNotes;

  // Joined data (optional, populated by queries)
  final Map<String, dynamic>? deliveryRequest;
  final Map<String, dynamic>? rider;
  final Map<String, dynamic>? dispatcher;

  const DeliveryIssueModel({
    required this.issueID,
    required this.requestID,
    required this.riderID,
    this.dispatcherID,
    required this.issueType,
    this.description,
    required this.dateTimeReported,
    this.resolvedFlag = false,
    this.resolvedDateTime,
    this.resolvedBy,
    this.resolutionNotes,
    this.deliveryRequest,
    this.rider,
    this.dispatcher,
  });

  factory DeliveryIssueModel.fromJson(Map<String, dynamic> json) {
    return DeliveryIssueModel(
      issueID: json['issueid'] ?? '',
      requestID: json['requestid'] ?? '',
      riderID: json['riderid'] ?? '',
      dispatcherID: json['dispatcherid'],
      issueType: json['issue_type'] ?? 'customer',
      description: json['description'],
      dateTimeReported: json['datetimereported'] != null
          ? DateTime.parse(json['datetimereported'])
          : DateTime.now(),
      resolvedFlag: json['resolvedflag'] ?? false,
      resolvedDateTime: json['resolveddatetime'] != null
          ? DateTime.parse(json['resolveddatetime'])
          : null,
      resolvedBy: json['resolvedby'],
      resolutionNotes: json['resolutionnotes'],
      deliveryRequest: json['delivery_request'],
      rider: json['rider'],
      dispatcher: json['dispatcher'],
    );
  }

  Map<String, dynamic> toJson() => {
        'issueid': issueID,
        'requestid': requestID,
        'riderid': riderID,
        'dispatcherid': dispatcherID,
        'issue_type': issueType,
        'description': description,
        'datetimereported': dateTimeReported.toIso8601String(),
        'resolvedflag': resolvedFlag,
        'resolveddatetime': resolvedDateTime?.toIso8601String(),
        'resolvedby': resolvedBy,
        'resolutionnotes': resolutionNotes,
      };

  DeliveryIssueModel copyWith({
    String? issueID,
    String? requestID,
    String? riderID,
    String? dispatcherID,
    String? issueType,
    String? description,
    DateTime? dateTimeReported,
    bool? resolvedFlag,
    DateTime? resolvedDateTime,
    String? resolvedBy,
    String? resolutionNotes,
    Map<String, dynamic>? deliveryRequest,
    Map<String, dynamic>? rider,
    Map<String, dynamic>? dispatcher,
  }) {
    return DeliveryIssueModel(
      issueID: issueID ?? this.issueID,
      requestID: requestID ?? this.requestID,
      riderID: riderID ?? this.riderID,
      dispatcherID: dispatcherID ?? this.dispatcherID,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      dateTimeReported: dateTimeReported ?? this.dateTimeReported,
      resolvedFlag: resolvedFlag ?? this.resolvedFlag,
      resolvedDateTime: resolvedDateTime ?? this.resolvedDateTime,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      deliveryRequest: deliveryRequest ?? this.deliveryRequest,
      rider: rider ?? this.rider,
      dispatcher: dispatcher ?? this.dispatcher,
    );
  }

  // ─── Convenience getters ───────────────────────────────────
  bool get isCustomerIssue => issueType == 'customer';
  bool get isRiderCompletedIssue => issueType == 'rider_completed';
  bool get isRiderCancelledIssue => issueType == 'rider_cancelled';

  /// Label shown in the UI
  String get issueTypeLabel {
    switch (issueType) {
      case 'customer':
        return 'Customer Complaint';
      case 'rider_completed':
        return 'Rider Issue (Completed)';
      case 'rider_cancelled':
        return 'Rider Issue (Cancelled)';
      default:
        return issueType;
    }
  }

  /// Who is allowed to resolve this issue
  String get resolverRole {
    switch (issueType) {
      case 'customer':
        return 'Dispatcher or Management';
      case 'rider_completed':
        return 'Management';
      case 'rider_cancelled':
        return 'Dispatcher';
      default:
        return 'Unknown';
    }
  }
}