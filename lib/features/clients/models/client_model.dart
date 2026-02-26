class ClientModel {
  final String clientId;
  final String name;
  final String address;
  final String sites;
  final String contactName;
  final String contactPhone;
  final String contactEmail;

  ClientModel({
    required this.clientId,
    required this.name,
    required this.address,
    required this.sites,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
  });



  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      clientId: json['Client_ID']?.toString().trim() ?? '',
      name: json['Name']?.toString().trim() ?? '',
      address: json['Address']?.toString().trim() ?? '',
      sites: json['Sites']?.toString().trim() ?? '',
      contactName: json['Contact_Name']?.toString().trim() ?? '',
      contactPhone: json['Contact_Phone']?.toString().trim() ?? '',
      contactEmail: json['Contact_Email']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Client_ID': clientId,
      'Name': name,
      'Address': address,
      'Sites': sites,
      'Contact_Name': contactName,
      'Contact_Phone': contactPhone,
      'Contact_Email': contactEmail,
    };
  }
}
