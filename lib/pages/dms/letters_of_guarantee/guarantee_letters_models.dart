import 'package:intl/intl.dart';

class DmsLetter {
  final String id;
  final String date;
  final String dateEnd;
  final String lpuName;
  final String requestTypeName;

  DmsLetter({
    required this.id,
    required this.date,
    required this.dateEnd,
    required this.lpuName,
    required this.requestTypeName,
  });

  bool get isActive {
    final DateTime date = DateFormat('dd.MM.yyyy').parse(dateEnd);
    final DateTime now = DateTime.now();
    return now.isBefore(date.add(const Duration(days: 1)));
  }

  factory DmsLetter.fromJson(Map<String, dynamic> json) {

    return DmsLetter(
      id: json['FileID'] as String,
      date: json['Date'] as String,
      dateEnd: json['DateEnd'] as String,
      lpuName: json['LpuName'] as String,
      requestTypeName: json['DmsLetterRequestTypeName'] as String,
    );
  }
}

class DmsLetterRequestCountType {
  final String code;
  final String name;

  DmsLetterRequestCountType({
    required this.code,
    required this.name,
  });
}

class DmsLetterRequestType {
  final String code;
  final String name;

  DmsLetterRequestType({
    required this.code,
    required this.name,
  });

  factory DmsLetterRequestType.fromJson(Map<String, dynamic> json) {
    return DmsLetterRequestType(
      code: json['Code'] as String,
      name: json['Name'] as String,
    );
  }
}

class DmsLetterContactType {
  final String code;
  final String name;

  DmsLetterContactType({
    required this.code,
    required this.name,
  });
}