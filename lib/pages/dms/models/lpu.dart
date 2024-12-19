class DmsLpu {
  DmsLpu({
    this.index,
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.phones,
  });

  final int? index;
  final String id;
  final String name;
  final String address;
  final String? latitude;
  final String? longitude;
  final List<String>? phones;
}
