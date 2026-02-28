import 'package:fsm_app/export.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  /// Fetch data (GET) from a specific table with Cache-Busting
  static Future<List<dynamic>> getTableData(String tableName) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.scriptUrl}?table=$tableName&t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return decoded['data'];
        } else {
          throw Exception(decoded['message']);
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('API GET Error: $e');
      return [];
    }
  }

  /// Insert data (POST) to a specific table
  static Future<bool> insertRecord(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.scriptUrl);
      final payload = jsonEncode({
        "action": "insert",
        "table": tableName,
        "data": data,
      });

      // Dropping the application/json header bypasses the Web CORS block
      final response = await http.post(uri, body: payload);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final decoded = jsonDecode(response.body);
        return decoded['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('API POST Error: $e');
      return false;
    }
  }

  /// Update an existing record (POST)
  static Future<bool> updateRecord(
    String tableName,
    String idField,
    String idValue,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.scriptUrl);
      final payload = jsonEncode({
        "action": "update",
        "table": tableName,
        "idField": idField,
        "idValue": idValue,
        "data": data,
      });

      // Dropping the application/json header bypasses the Web CORS block
      final response = await http.post(uri, body: payload);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final decoded = jsonDecode(response.body);
        return decoded['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('API UPDATE Error: $e');
      return false;
    }
  }

  /// Delete a record (POST)
  static Future<bool> deleteRecord(
    String tableName,
    String idField,
    String idValue,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.scriptUrl);
      final payload = jsonEncode({
        "action": "delete", // Ensure your Google Apps Script handles "delete"
        "table": tableName,
        "idField": idField,
        "idValue": idValue,
      });

      final response = await http.post(uri, body: payload);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final decoded = jsonDecode(response.body);
        return decoded['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('API DELETE Error: $e');
      return false;
    }
  }

  /// Update a record and return the exact error message if it fails
  static Future<String?> updateRecordDetailed(
    String tableName,
    String idField,
    String idValue,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse(ApiConstants.scriptUrl);
      final payload = jsonEncode({
        "action": "update",
        "table": tableName,
        "idField": idField,
        "idValue": idValue,
        "data": data,
      });

      // Dropping the application/json header bypasses the Web CORS block
      final response = await http.post(uri, body: payload);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return null; // Null means success
        } else {
          return decoded['message']; // Returns exactly what Apps Script complained about
        }
      }
      return 'HTTP Error: ${response.statusCode}';
    } catch (e) {
      return 'Network Exception: $e';
    }
  }

  /// Request Email Verification (GET)
  static Future<String?> requestEmailVerification(String email) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.scriptUrl}?action=send_verification&email=${Uri.encodeComponent(email)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          return null;
        } else {
          return decoded['message'];
        }
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Network exception: $e';
    }
  }
}
