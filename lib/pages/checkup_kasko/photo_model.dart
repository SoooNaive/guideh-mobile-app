import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart';

class CheckupKaskoPhoto {
  CheckupKaskoPhoto({
    this.name,
    this.path,
    this.prefix,
    this.data,
    this.check,
    required this.type,
    this.latitude,
    this.longitude,
  });
  final String? name;
  final String? path;
  final String? prefix;
  final String? data;
  final String? check;
  final String type;
  final double? latitude;
  final double? longitude;

  factory CheckupKaskoPhoto.fromMap(Map<String, dynamic> json) {
    final name = json['Name'] as String?;
    final type = json['Type'] as String;
    final check = json['Check'] as String?;
    final prefix = json['Prefix'] as String?;
    final data = json['Data'].replaceAll("\r\n", "") as String?;
    final latitude = json['Latitude'] == null ? null : double.parse(json['Latitude']);
    final longitude = json['Latitude'] == null ? null : double.parse(json['Longitude']);
    return CheckupKaskoPhoto(
      name: name,
      type: type,
      check: check,
      prefix: prefix,
      data: data,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // конвертим объект CheckupKaskoPhoto в json
  Map<String, dynamic> toJson() {
    if (path == null) return {};
    return {
      'Name': basename(path!),
      'Prefix': 'data:${lookupMimeType(path!)};base64,',
      'Type': type,
      'Data': base64.encode(File(path!).readAsBytesSync()),
      'Latitude': latitude.toString(),
      'Longitude': longitude.toString(),
    };
  }

}