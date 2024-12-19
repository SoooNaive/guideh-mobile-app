class KaskoDriver {
  KaskoDriver({
    required this.name,
    required this.birthdate,
    required this.docSeries,
    required this.docNumber,
    this.docPhotoPaths,
  });

  final String name;
  final String birthdate;
  final String docSeries;
  final String docNumber;
  final List<String>? docPhotoPaths;

  // конвертим json в объект KaskoDriver
  factory KaskoDriver.fromJson(Map<String, dynamic> json) {
    final name = json['Name'] as String;
    final birthdate = json['Birthdate'] as String;
    final docSeries = json['DocSeries'] as String;
    final docNumber = json['DocNumber'] as String;
    return KaskoDriver(
      name: name,
      birthdate: birthdate,
      docSeries: docSeries,
      docNumber: docNumber,
    );
  }
}
