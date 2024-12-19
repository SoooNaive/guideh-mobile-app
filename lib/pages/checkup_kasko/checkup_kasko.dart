import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/step_car_photos.dart';
import 'package:guideh/pages/checkup_kasko/step_damage_photos.dart';
import 'package:guideh/pages/checkup_kasko/step_extra_photos.dart';
import 'package:guideh/services/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'photo_model.dart';

List<Map<String, String>> extraPhotosData = [
  {
    'name': 'document',
    'title': 'Документ (СТС или ПТС)',
  }, {
    'name': 'documentBack',
    'title': 'Документ (обратная сторона)',
  }, {
    'name': 'kilometrage',
    'title': 'Пробег',
  }, {
    'name': 'keys',
    'title': 'Комплекты ключей',
  }, {
    'name': 'interiorFront',
    'title': 'Салон: передние кресла',
  }, {
    'name': 'interiorRear',
    'title': 'Салон: задние кресла',
  }, {
    'name': 'vin',
    'title': 'VIN-номер',
  }, {
    'name': 'windshield',
    'title': 'Лобовое стекло',
  }, {
    'name': 'wheel',
    'title': 'Колесо',
  },
];

bool hasDeniedPhotos(List<CheckupKaskoPhoto> photos, String stepName) {
  if (photos.isEmpty) return false;
  final List<CheckupKaskoPhoto> deniedPhotos =
    photos.where((photo) => photo.check == '0').toList();
  final List<String> deniedPhotosTypes =
    deniedPhotos.map((photo) => photo.type).toList();
  switch (stepName) {
    case 'car_photos':
      return deniedPhotosTypes.any(['0','1','2','3','4','5','6','7'].contains);
    case 'extra_photos':
      return deniedPhotosTypes.any(
          extraPhotosData.map((item) => item['name']).toSet().contains
      );
  }
  return false;
}

class CheckupKasko extends StatefulWidget {
  final String? parentId;
  final String? parentIdType;
  final Map<String, dynamic>? checkupData;
  final String? stepName;

  const CheckupKasko({
    super.key,
    required this.parentId,
    required this.parentIdType,
    required this.checkupData,
    this.stepName,
  });

  @override
  State<CheckupKasko> createState() => _CheckupKaskoState();
}

class _CheckupKaskoState extends State<CheckupKasko> {

  late String stepName;
  late CheckupKaskoBloc checkupKaskoBloc;
  List<CheckupKaskoPhoto> casePhotos = [];

  @override
  void initState() {
    stepName = widget.stepName ?? 'car_photos';
    checkupKaskoBloc = CheckupKaskoBloc();

    // запишем фотки из кейса в bloc
    final photosData = widget.checkupData?['Case']?['Files'] as List<dynamic>?;
    if (photosData != null) {
      casePhotos = photosData.map((photoData) => CheckupKaskoPhoto.fromMap(photoData)).toList();
      checkupKaskoBloc.add(CheckupKaskoAddCasePhotos(casePhotos));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<CheckupKaskoBloc>(
            create: (context) => checkupKaskoBloc,
          ),
        ],
        child: stepName == 'car_photos'
          ? CheckupKaskoStepCarPhotos(
            goToNextStepFrom: goToNextStepFrom,
            parentId: widget.parentId ?? '',
          )
          : stepName == 'damage_photos'
            ? CheckupKaskoStepDamagePhotos(
              goToNextStepFrom: goToNextStepFrom,
              parentId: widget.parentId ?? '',
            )
            : stepName == 'extra_photos'
              ? CheckupKaskoStepExtraPhotos(
                goToNextStepFrom: goToNextStepFrom,
                parentId: widget.parentId ?? '',
                stepHasDeniedPhotos: hasDeniedPhotos(casePhotos, 'extra_photos'),
              )
              : Center(child: Text('Не определён шаг: $stepName'))
    );
  }

  void goToNextStepFrom(String previousStepName) async {
    switch (previousStepName) {
      case 'car_photos':
        if (widget.checkupData == null) {
          // goto 2
          setState(() => stepName = 'damage_photos');
        }
        else if (hasDeniedPhotos(casePhotos, 'extra_photos')) {
          // goto 3
          setState(() => stepName = 'extra_photos');
        }
        else {
          _checkupIsDone();
        }
        break;
      case 'damage_photos':
        if (widget.checkupData == null || hasDeniedPhotos(casePhotos, 'extra_photos')) {
          // goto 3
          setState(() => stepName = 'extra_photos');
        }
        else {
          _checkupIsDone();
        }
        break;
      case 'extra_photos':
        _checkupIsDone();
        break;
      default:
        print('Ошибка: не определён предыдущий шаг');
    }
  }

  // конец
  void _checkupIsDone() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final saveResponse = await Http.mobApp(
        ApiParams('Checkup', 'DocSaveCheck', {
          'Phone': preferences.getString('phone') ?? '',
          'DocId': preferences.getString('draftKaskoCheckupId') ?? '',
          'StatusId': 31,
        })
    );
    print({
      'Phone': preferences.getString('phone') ?? '',
      'DocId': preferences.getString('draftKaskoCheckupId') ?? '',
      'StatusId': 31,
    });
    print(saveResponse);
    if (!saveResponse.containsKey('Error') || saveResponse['Error'] == 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
              content: Column(
              children: [
                const Text('Ошибка отправки на проверку.'
                  ' Повторите попытку или обратитесь в поддержку.'),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => _checkupIsDone(),
                  child: const Text('Повторить'),
                )
              ],
            )
          ),
        );
      }
      return;
    }

    if (mounted) {
      context.goNamed('checkup_kasko_done');
    }
  }

}
