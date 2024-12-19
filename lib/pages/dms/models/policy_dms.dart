import 'package:intl/intl.dart';

class PolicyDMS {
  PolicyDMS({
    required this.docId,
    required this.docNumber,
    required this.dateS,
    required this.dateE,
    required this.insurer,
    required this.insured
  });

  final String docId;
  final String docNumber;
  final String dateS;
  final String dateE;
  final String insurer;
  final String insured;

  factory PolicyDMS.fromJson(Map<String, dynamic> json) {
    DateTime parsedDateS = DateTime.parse(json['DateS']);
    DateTime parsedDateE = DateTime.parse(json['DateE']);
    return PolicyDMS(
      docId: json['DocId'] as String,
      docNumber: json['DocNumber'] as String,
      dateS: DateFormat('dd.MM.yyyy').format(parsedDateS),
      dateE: DateFormat('dd.MM.yyyy').format(parsedDateE),
      insurer: json['Insurer'] as String,
      insured: json['Insured'] as String,
    );
  }
}