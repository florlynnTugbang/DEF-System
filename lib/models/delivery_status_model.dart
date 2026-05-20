class DeliveryStatusModel {
  final int statusID;
  final String statusName;

  DeliveryStatusModel({
    required this.statusID,
    required this.statusName,
  });

  factory DeliveryStatusModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusModel(
      statusID: json['statusid'],
      statusName: json['statusname'],
    );
  }

  Map<String, dynamic> toJson() => {
    'statusid': statusID,
    'statusname': statusName,
  };
}