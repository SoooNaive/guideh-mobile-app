import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class B2BOsagoAddPhoto {
  B2BOsagoAddPhoto({
    this.contractId,
    required this.path,
    required this.type,
  });
  final String? contractId;
  final String path;
  final String type;

  // конвертим объект B2BOsagoAddPhoto в json
  Map<String, dynamic> toJson() {
    return {
      'name': '${contractId != null ? '${contractId}_' : ''}$type${p.extension(path)}',
      'data': 'data:${lookupMimeType(path)};base64,${base64.encode(File(path).readAsBytesSync())}',
    };
  }
}