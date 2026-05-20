class DispatcherModel {
  final String dispatcherID;
  final String disFname;
  final String? disMname;
  final String disLname;
  final String? contactNumber;
  final String? username;

  DispatcherModel({
    required this.dispatcherID,
    required this.disFname,
    this.disMname,
    required this.disLname,
    this.contactNumber,
    this.username,
  });

  String get fullName => [disFname, disMname, disLname]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');

  factory DispatcherModel.fromJson(Map<String, dynamic> json) {
    return DispatcherModel(
      dispatcherID: json['dispatcherid'],     // ← fixed
      disFname: json['disfname'],             // ← fixed
      disMname: json['dismname'],             // ← fixed
      disLname: json['dislname'],             // ← fixed
      contactNumber: json['contactnumber'],   // ← fixed
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() => {
    'disfname': disFname,
    'dismname': disMname,
    'dislname': disLname,
    'contactnumber': contactNumber,
    'username': username,
  };
}