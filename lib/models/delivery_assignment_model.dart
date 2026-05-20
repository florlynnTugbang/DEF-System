class DeliveryAssignmentModel {
  final String assignmentID;
  final String requestID;
  final String riderID;
  final String dispatcherID;
  final DateTime assignmentDateTime;
  final String assignmentStatus;
  final DateTime? completedDateTime;

  DeliveryAssignmentModel({
    required this.assignmentID,
    required this.requestID,
    required this.riderID,
    required this.dispatcherID,
    required this.assignmentDateTime,
    required this.assignmentStatus,
    this.completedDateTime,
  });

  factory DeliveryAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAssignmentModel(
      assignmentID: json['assignmentid'],
      requestID: json['requestid'],
      riderID: json['riderid'],
      dispatcherID: json['dispatcherid'],
      assignmentDateTime: DateTime.parse(json['assignmentdatetime']),
      assignmentStatus: json['assignmentstatus'],
      completedDateTime: json['completeddatetime'] != null
          ? DateTime.parse(json['completeddatetime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'requestid': requestID,
    'riderid': riderID,
    'dispatcherid': dispatcherID,
    'assignmentstatus': assignmentStatus,
    'completeddatetime': completedDateTime?.toIso8601String(),
  };
}