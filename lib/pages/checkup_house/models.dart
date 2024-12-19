import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guideh/pages/checkup_house/functions.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';


// case object

class CheckupHouseCaseObject {
  CheckupHouseCaseObject({
    required this.type,
    this.parent,
    this.name,
    this.photos,
    this.photosPath,
    this.photosPathLocation,
    this.invalid,
    this.check,
    this.comment,
  });

  final String type;
  final String? parent;
  String? name;
  final List<Photo>? photos;
  final List<String>? photosPath;
  List<Position?>? photosPathLocation;
  bool? invalid;
  bool? check;
  String? comment;

  // конвертим json в объект CheckupHouseCaseObject
  factory CheckupHouseCaseObject.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final parent = json['parent'] != '' ? json['parent'] : null;
    final name = json['name'] != '' ? json['name'] : null;
    final photosData = json['photos'] as List<dynamic>?;
    final photos = photosData != null
        ? photosData.map((photoData) => Photo.fromMap(photoData)).toList()
        : <Photo>[];
    final check = json['check'] != '' ? (json['check'] == '1') : null;
    final comment = json['comment'] as String?;
    return CheckupHouseCaseObject(
      type: type,
      parent: parent,
      name: name,
      photos: photos,
      photosPath: <String>[],
      photosPathLocation: <Position?>[],
      check: check,
      comment: comment,
    );
  }

  // конвертим объект CheckupHouseCaseObject в json
  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> allPhotos = [];
    // это для отправки на бэк - сохраняем только новые фотки
    if (photosPath != null) {
      allPhotos.addAll(photosPath!.mapIndexed((int photoIndex, String photoPath) => {
        'name': basename(photoPath),
        'prefix': 'data:${lookupMimeType(photoPath)};base64,',
        'data': base64.encode(File(photoPath).readAsBytesSync()),
        'latitude': photosPathLocation?[photoIndex]?.latitude,
        'longitude': photosPathLocation?[photoIndex]?.longitude,
      }));
    }
    return {
      'type': type,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      'photos': allPhotos,
    };
  }

  // получить общее кол-во фоток
  int get photosCount => (photos?.length ?? 0) + (photosPath?.length ?? 0);

  // есть ли неодобренные фотки?
  bool get hasInvalidPhotos => photos?.any((el) => el.invalid ?? false) ?? false;

  // вернуть объект шага, соответстующего этому объекту кейса
  StepData? get getStep => getStepByType(type);

}

// photo

class Photo {
  Photo({
    this.id,
    required this.name,
    required this.prefix,
    required this.data,
    required this.latitude,
    required this.longitude,
    this.invalid,
  });
  final String? id;
  final String name;
  final String prefix;
  final String data;
  final double latitude;
  final double longitude;
  final bool? invalid;

  factory Photo.fromMap(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final prefix = json['prefix'] as String;
    final data = json['data'].replaceAll("\r\n", "") as String;
    final latitude = json['latitude'] as double;
    final longitude = json['longitude'] as double;
    final invalid = json['invalid'] as bool?;
    return Photo(
        name: name,
        prefix: prefix,
        data: data,
        latitude: latitude,
        longitude: longitude,
        invalid: invalid,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'prefix': prefix,
    'data': data,
    'latitude': latitude,
    'longitude': longitude,
    if (invalid != null) 'invalid': invalid,
  };

}

class StepData {
  final String type;
  final String title;
  final Function? child;
  final int? minPhotos;
  StepStatus? status;

  StepData({
    required this.type,
    required this.title,
    this.child,
    this.minPhotos,
    this.status,
  });
}

enum StepStatus {
  valid,
  invalid,
}


class CheckupHouseStepContent {
  final Widget title;
  final Widget content;
  final Widget bottom;

  CheckupHouseStepContent({
    required this.title,
    required this.content,
    required this.bottom,
  });
}


class CommentAlert extends StatelessWidget {
  final String? comment;
  final bool? check;
  const CommentAlert(this.comment, this.check, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: check != null ? (
          check! ? const Color(0xffe4f2c9) : const Color(0xfffed5d0)
        ) : const Color(0xffeeeeee),
        borderRadius: const BorderRadius.all(Radius.circular(5))
      ),
      child: Text(
        comment ?? '[нет комментария]',
        style: TextStyle(
          color: check != null ? (
            check! ? const Color(0xff3c763d) : const Color(0xffa94442)
          ) : Colors.black
        ),
      ),
    );
  }
}
