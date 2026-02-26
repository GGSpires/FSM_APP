import 'package:intl/intl.dart';

class JobCardModel {
  final String jcId;
  final String worksNo;
  final String clientRef;
  final String orderNo;
  final String tech;
  final String client;
  final String site;
  final String contact;
  final DateTime date;
  final DateTime timeIn;
  final DateTime? timeOut;
  final String workInstruction;
  final String workExecuted;
  final String remarks;
  final String callComplete;
  final String returnNeeded;
  final String clientName;
  final String clientSign;
  final String techSign;

  JobCardModel({
    required this.jcId,
    required this.worksNo,
    this.clientRef = '',
    this.orderNo = '',
    required this.tech,
    required this.client,
    required this.site,
    required this.contact,
    required this.date,
    required this.timeIn,
    this.timeOut,
    required this.workInstruction,
    required this.workExecuted,
    this.remarks = '',
    required this.callComplete,
    required this.returnNeeded,
    this.clientName = '',
    this.clientSign = '',
    this.techSign = '',
  });

  factory JobCardModel.fromJson(Map<String, dynamic> json) {
    // --- 1. THE BULLETPROOF DATE PARSER ---
    DateTime safeParseDate(String? dateStr) {
      if (dateStr == null || dateStr.trim().isEmpty) return DateTime.now();
      String cleanStr = dateStr.trim();

      try {
        // Strip out any hidden time data Google Sheets might have attached
        if (cleanStr.contains(' ')) {
          cleanStr = cleanStr.split(' ')[0]; // Keeps only the date part
        }

        // 1. Try ISO Format (e.g., "2023-08-24" or "2023-08-24T00:00:00.000Z")
        DateTime? parsed = DateTime.tryParse(cleanStr);
        if (parsed != null) return parsed;

        // 2. Manual Slash Parsing (Destroys formatting errors)
        if (cleanStr.contains('/')) {
          List<String> parts = cleanStr.split('/');
          if (parts.length == 3) {
            // Check if it's YYYY/MM/DD or DD/MM/YYYY
            if (parts[0].length == 4) {
              return DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            } else {
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        }

        return DateTime.now();
      } catch (e) {
        // We print the exact error so you can see what Google is sending!
        print('CRITICAL PARSE ERROR: Could not parse Date "$dateStr" - $e');
        return DateTime.now();
      }
    }

    // --- 2. THE BULLETPROOF TIME PARSER ---
    DateTime safeParseTime(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return DateTime.now();
      }
      String valStr = value.toString().trim();

      try {
        // Isolate time if Google sent "DD/MM/YYYY HH:mm:ss"
        if (valStr.contains(' ')) {
          valStr = valStr.split(' ').last;
        }

        // If it has a colon, manually extract Hours and Minutes
        if (valStr.contains(':')) {
          List<String> parts = valStr.split(':');
          final now = DateTime.now();
          // Rebuild a DateTime using today's date, but the exact hours/mins from the database
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }

        // Fallback for strict ISO timestamps
        return DateTime.tryParse(valStr) ?? DateTime.now();
      } catch (e) {
        print('CRITICAL PARSE ERROR: Could not parse Time "$value" - $e');
        return DateTime.now();
      }
    }

    DateTime? safeParseTimeOut(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      return safeParseTime(value);
    }

    return JobCardModel(
      jcId: json['JC_ID']?.toString().padLeft(4, '0') ?? '0000',
      worksNo: json['Works_No']?.toString() ?? '',
      clientRef: json['Client_Ref']?.toString() ?? '',
      orderNo: json['Order_No']?.toString() ?? '',
      tech: json['Tech']?.toString() ?? '',
      client: json['Client']?.toString() ?? '',
      site: json['Site']?.toString() ?? '',
      contact: json['Contact']?.toString() ?? '',

      // Applied safe parsers
      date: safeParseDate(json['Date']?.toString()),
      timeIn: safeParseTime(json['Time_In']?.toString()),
      timeOut: safeParseTimeOut(json['Time_Out']?.toString()),

      workInstruction: json['Work_Instruction']?.toString() ?? '',
      workExecuted: json['Work_Executed']?.toString() ?? '',
      remarks: json['Remarks']?.toString() ?? '',
      callComplete: json['Call_Complete']?.toString() ?? 'FALSE',
      returnNeeded: json['Return_Needed']?.toString() ?? 'FALSE',
      clientName: json['Client_Name']?.toString() ?? '',
      clientSign: json['Client_Sign']?.toString() ?? '',
      techSign: json['Tech_Sign']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'JC_ID': jcId,
      'Works_No': worksNo,
      'Client_Ref': clientRef,
      'Order_No': orderNo,
      'Tech': tech,
      'Client': client,
      'Site': site,
      'Contact': contact,
      'Date': DateFormat('dd/MM/yyyy').format(date),
      'Time_In': DateFormat('HH:mm').format(timeIn),
      'Time_Out': timeOut != null ? DateFormat('HH:mm').format(timeOut!) : '',
      'Work_Instruction': workInstruction,
      'Work_Executed': workExecuted,
      'Remarks': remarks,
      'Call_Complete': callComplete,
      'Return_Needed': returnNeeded,
      'Client_Name': clientName,
      'Client_Sign': clientSign,
      'Tech_Sign': techSign,
    };
  }
}
