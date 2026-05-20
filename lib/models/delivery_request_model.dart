class DeliveryRequestModel {
  final String requestID;
  final String? customerID;
  final String? dispatcherID;
  final int statusID;
  final DateTime requestDateTime;
  final String pickupAddress;
  final String deliveryAddress;
  final String? itemDescription;
  final String? specialInstructions;

  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? assignment;
  final Map<String, dynamic>? deliveryStatus;
  final Map<String, dynamic>? dispatcher;

  DeliveryRequestModel({
    required this.requestID,
    this.customerID,
    this.dispatcherID,
    required this.statusID,
    required this.requestDateTime,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.itemDescription,
    this.specialInstructions,
    this.customer,
    this.assignment,
    this.deliveryStatus,
    this.dispatcher,
  });

  factory DeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    final deliveryStatus = json['delivery_status'];

    return DeliveryRequestModel(
      requestID: json['requestid']?.toString() ?? '',
      customerID: json['customerid']?.toString(),
      dispatcherID: json['dispatcher_id']?.toString() ??
          json['dispatcherid']?.toString(),
      statusID: deliveryStatus != null
          ? deliveryStatus['statusid']
          : json['statusid'] ?? 1,
      requestDateTime: json['requestdatetime'] != null
          ? DateTime.parse(json['requestdatetime'].toString())
          : DateTime.now(),
      pickupAddress: json['pickupaddress']?.toString() ?? '',
      deliveryAddress: json['deliveryaddress']?.toString() ?? '',
      itemDescription: json['itemdescription']?.toString(),
      specialInstructions: json['specialinstructions']?.toString(),
      customer: json['customer'],
      dispatcher: json['dispatcher'],
      assignment: json['delivery_assignment'] is List
          ? (json['delivery_assignment'] as List).isNotEmpty
          ? json['delivery_assignment'][0]
          : null
          : json['delivery_assignment'],
      deliveryStatus: deliveryStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'customerid': customerID,
    'dispatcher_id': dispatcherID,
    'statusid': statusID,
    'pickupaddress': pickupAddress,
    'deliveryaddress': deliveryAddress,
    'itemdescription': itemDescription,
    'specialinstructions': specialInstructions,
  };
}