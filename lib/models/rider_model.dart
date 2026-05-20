class RiderModel {
  final String riderID;
  final String riderFname;
  final String? riderMname;
  final String riderLname;
  final String? contactNumber;
  final String? vehicleDetails;
  final bool availabilityStatus;
  final String? username;

  RiderModel({
    required this.riderID,
    required this.riderFname,
    this.riderMname,
    required this.riderLname,
    this.contactNumber,
    this.vehicleDetails,
    this.availabilityStatus = true,
    this.username,
  });

  String get fullName => [riderFname, riderMname, riderLname]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      riderID: json['riderid'],                         // ← fixed
      riderFname: json['riderfname'],                   // ← fixed
      riderMname: json['ridermname'],                   // ← fixed
      riderLname: json['riderlname'],                   // ← fixed
      contactNumber: json['contactnumber'],             // ← fixed
      vehicleDetails: json['vehicledetails'],           // ← fixed
      availabilityStatus: json['availabilitystatus'] ?? true, // ← fixed
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() => {
    'riderfname': riderFname,
    'ridermname': riderMname,
    'riderlname': riderLname,
    'contactnumber': contactNumber,
    'vehicledetails': vehicleDetails,
    'availabilitystatus': availabilityStatus,
    'username': username,
  };
}