class CustomerModel {
  final String customerID;
  final String custFname;
  final String? custMname;
  final String custLname;
  final String? contactNumber;
  final String? address;
  final String? email;

  CustomerModel({
    required this.customerID,
    required this.custFname,
    this.custMname,
    required this.custLname,
    this.contactNumber,
    this.address,
    this.email,
  });

  String get fullName => [custFname, custMname, custLname]
      .where((e) => e != null && e.isNotEmpty)
      .join(' ');

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerID: json['customerid'],
      custFname: json['custfname'],
      custMname: json['custmname'],
      custLname: json['custlname'],
      contactNumber: json['contactnumber'],
      address: json['address'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'custfname': custFname,
    'custmname': custMname,
    'custlname': custLname,
    'contactnumber': contactNumber,
    'address': address,
    'email': email,
  };
}