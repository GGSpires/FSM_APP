import 'package:intl/intl.dart';

class UserModel {
  final String userId;
  final String role;
  final String name;
  final String alias;
  final String position;
  final String email;
  final String password;
  final String contact;
  final String address;
  final DateTime hireDate;
  final DateTime lastOnline;
  final String photo;
  final String emailVerified;

  UserModel({
    required this.userId,
    required this.role,
    required this.name,
    required this.alias,
    required this.position,
    required this.email,
    required this.password,
    this.contact = '',
    this.address = '',
    required this.hireDate,
    required this.lastOnline,
    this.photo = '',
    this.emailVerified = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse Google Sheets date formats
    DateTime safeParseDate(String? dateStr) {
      if (dateStr == null || dateStr.trim().isEmpty) {
        return DateTime(2000, 1, 1); // Fallback for blank cells
      }
      try {
        // Try to parse the Google Sheets format: DD/MM/YYYY HH:mm:ss
        if (dateStr.contains(' ')) {
          return DateFormat('dd/MM/yyyy HH:mm:ss').parse(dateStr);
        }
        // Try to parse just the date: DD/MM/YYYY
        return DateFormat('dd/MM/yyyy').parse(dateStr);
      } catch (e) {
        // If all else fails, attempt standard ISO parse or return fallback
        return DateTime.tryParse(dateStr) ?? DateTime(2000, 1, 1);
      }
    }

    return UserModel(
      userId: json['User_ID']?.toString().trim() ?? '',
      role: json['Role']?.toString().trim() ?? '',
      name: json['Name']?.toString().trim() ?? '',
      alias: json['Alias']?.toString().trim() ?? '',
      position:
          json['Positition']?.toString().trim() ?? '', // Matches your CSV typo
      email: json['Email']?.toString().trim() ?? '',
      password: json['Password']?.toString() ?? '',
      contact: json['Contact']?.toString().trim() ?? '',
      address: json['Address']?.toString().trim() ?? '',
      hireDate: safeParseDate(json['HireDate']?.toString()),
      lastOnline: safeParseDate(json['LastOnline']?.toString()),
      photo: json['Photo']?.toString() ?? '',
      emailVerified: json['Email_Verified']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'User_ID': userId,
      'Role': role,
      'Name': name,
      'Alias': alias,
      'Positition': position,
      'Email': email,
      'Password': password,
      'Contact': contact,
      'Address': address,
      // Format back to Google Sheets style so the database stays clean
      'HireDate': DateFormat('dd/MM/yyyy').format(hireDate),
      'LastOnline': DateFormat('dd/MM/yyyy HH:mm:ss').format(lastOnline),
      'Photo': photo,
      'Email_Verified': emailVerified,
    };
  }
}
