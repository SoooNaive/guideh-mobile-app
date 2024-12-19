import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:guideh/pages/checkup_house/steps/01_outside.dart';
import 'package:guideh/pages/checkup_house/steps/02_inside.dart';
import 'package:guideh/pages/checkup_house/steps/03_01_outdoor.dart';
import 'package:guideh/pages/checkup_house/steps/03_02_locking.dart';
import 'package:guideh/pages/checkup_house/steps/03_03_indoors.dart';
import 'package:guideh/pages/checkup_house/steps/03_04_engineeringEquipment.dart';
import 'package:guideh/pages/checkup_house/steps/03_05_gasAndFireplaces.dart';
import 'package:guideh/pages/checkup_house/steps/03_06_otherEngineeringEquipment.dart';
import 'package:guideh/pages/checkup_house/steps/03_07_alarmSystems.dart';
import 'package:guideh/pages/checkup_house/steps/03_08_damage.dart';

import 'models.dart';



// шаги основные

final List<StepData> stepsMain = [
  StepData(
    type: 'outside',
    title: 'Фото подъездных путей (дороги), ограждения с привязкой к основному строению',
    child: (step, caseObject) => CheckupHouseStepOutside(step, caseObject),
    // todo: test
    minPhotos: 2,
  ),
  StepData(
    type: 'inside',
    title: 'Фото внутри участка с привязкой к основному строению и ограждению',
    child: (step, caseObject) => CheckupHouseStepInside(step, caseObject),
    // todo: test
    minPhotos: 2,
  ),
  StepData(
    type: 'buildings',
    title: 'Фото строений',
  ),
];

StepData? getStepByType(String type) {
  int stepIndex = allSteps.indexWhere((step) => step.type == type);
  return stepIndex != -1 ? allSteps[stepIndex] : null;
}

// шаги строения

final List<StepData> stepsBuilding = [
  StepData(
    type: 'outdoor',
    title: 'Фото строения снаружи',
    child: (step, caseObject) => CheckupHouseStepBuildingOutdoor(step, caseObject),
    // todo: test
    minPhotos: 2,
  ),
  StepData(
    type: 'locking',
    title: 'Фото входной двери, ворот, рольставен, решеток и т.д.',
    child: (step, caseObject) => CheckupHouseStepBuildingLocking(step, caseObject),
    // todo: test
    minPhotos: 1,
  ),
  StepData(
    type: 'indoors',
    title: 'Фото всех внутренних помещений',
    child: (step, caseObject) => CheckupHouseStepBuildingIndoors(step, caseObject),
    // todo: test
    minPhotos: 1,
  ),
  StepData(
    type: 'engineeringEquipment',
    title: 'Фото инженерного оборудования',
    child: (step, caseObject) => CheckupHouseStepBuildingEngineeringEquipment(step, caseObject),
  ),
  StepData(
    type: 'gasAndFireplaces',
    title: 'Газ / открытый огонь',
    child: (step, caseObject) => CheckupHouseStepBuildingGasAndFireplaces(step, caseObject),
  ),
  StepData(
    type: 'otherEngineeringEquipment',
    title: 'Прочее инженерное оборудование',
    child: (step, caseObject) => CheckupHouseStepBuildingOtherEngineeringEquipment(step, caseObject),
  ),
  StepData(
    type: 'alarmSystems',
    title: 'Фото охранной/пожарной систем',
    child: (step, caseObject) => CheckupHouseStepBuildingAlarmSystems(step, caseObject),
  ),
  StepData(
    type: 'damage',
    title: 'Фото всех имеющихся повреждений',
    child: (step, caseObject) => CheckupHouseStepBuildingDamage(step, caseObject),
  ),
];

final List<StepData> allSteps = [...stepsMain, ...stepsBuilding];


// объекты – стартовая структура для чистого кейса
final List<CheckupHouseCaseObject> defaultCaseObjects = [
  CheckupHouseCaseObject(
    type: 'outside',
    photos: [],
    photosPath: [],
  ),
  CheckupHouseCaseObject(
    type: 'inside',
    photos: [],
    photosPath: [],
  ),
  CheckupHouseCaseObject(
    type: 'buildings',
    photos: [],
    photosPath: [],
  ),
];


Future<bool> goNextStepDialog(BuildContext context, {
  required int? minPhotos,
  required int stepPhotosCount,
}) async {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  // проверка на min фотографий
  if (minPhotos != null) {
    if (stepPhotosCount < minPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Минимум $minPhotos фото'))
      );
      return false;
    }
  }
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('С этим закончили'),
        content: const SingleChildScrollView(
          child: Text('Перейти на следующий шаг?'),
        ),
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () => context.pop(false),
          ),
          TextButton(
            child: const Text('Следующий шаг'),
            onPressed: () => context.pop(true),
          ),
        ],
      );
    },
  ) ?? false;
}


// добавляем к строке инкремент, если такая строка уже есть в массиве
String addIncrementToString(String string, List<String>existingStrings) {
  String newString = string;
  int number = 2;
  while (existingStrings.contains(newString)) {
    newString = '$string ${number.toString()}';
    number++;
  }
  return newString;
}


// апдейт валидности основного шага (кроме buildings)
void updateStepStatus(StepData step, CheckupHouseCaseObject caseObject) {
  // todo: добавить caseObject.hasInvalidPhotos
  step.status = caseObject.photosCount < (step.minPhotos ?? 0)
    ? StepStatus.invalid : StepStatus.valid;
}

// апдейт валидности шага строений – проверяем все строения
void updateBuildingsStepStatus(List<CheckupHouseCaseObject> buildings) {
  final StepData buildingsStep = getStepByType('buildings')!;
  if (buildings.isEmpty) {
    buildingsStep.status = StepStatus.invalid;
    return;
  }
  for (var building in buildings) {
    if (building.invalid == true) {
      getStepByType('buildings')!.status = StepStatus.invalid;
      return;
    }
  }
  buildingsStep.status = StepStatus.valid;
}

// апдейт валидности ОБЪЕКТА строения
void updateBuildingObjectValidity(StepData step, CheckupHouseCaseObject caseObject) {
  // todo: добавить caseObject.hasInvalidPhotos
  caseObject.invalid = caseObject.photosCount < (step.minPhotos ?? 0);
}

// апдейт валидности объекта ШАГА строения
bool updateBuildingStepObjectValidity(
    StepData step,
    CheckupHouseCaseObject caseObject,
    [List<CheckupHouseCaseObject>? caseObjects]
    ) {
  // todo: добавить caseObject.hasInvalidPhotos
  final bool isInvalid = caseObject.photosCount < (step.minPhotos ?? 0);
  caseObject.invalid = isInvalid;

  // апдейт валидности объекта строения, если переданы caseObjects
  if (caseObjects != null) {
    bool buildingIsInvalid = false;
    final CheckupHouseCaseObject? buildingObject =
      caseObjects.firstWhereOrNull((obj) => obj.name == caseObject.parent);
    // если шаг инвалид - делаем само строение тоже инвалид
    if (isInvalid) {
      buildingIsInvalid = true;
    }
    // если нет - проверяем объекты шагов данного строения
    else {
      for (var caseObject in caseObjects.where((obj) => obj.parent == buildingObject?.name)) {
        // todo: найдены неодобренные фотки
        if (caseObject.invalid == true) {
          buildingIsInvalid = true;
          break;
        }
      }
    }

    if (buildingObject != null) {
      buildingObject.invalid = buildingIsInvalid;
      // апдейтим валидность шага Строения
      updateBuildingsStepStatus(caseObjects.where(
        (object) => object.parent == 'buildings'
      ).toList());
    }

  }

  return !isInvalid;
}


class ThumbnailsRow extends StatelessWidget {
  final List<Photo>? photos;
  final List<String>? photosPath;
  const ThumbnailsRow({super.key, this.photos, this.photosPath});

  @override
  Widget build(BuildContext context) {
    final List<Widget> elements = [];

    // print('photos: ${photos?.length}');
    // print('photosPath: ${photosPath?.length}');

    // показываем base64
    if (photos != null) {
      elements.addAll(photos!.map((photo) => Image.memory(base64Decode(photo.data))));
    }
    // показываем загруженные в память телефона
    if (photosPath != null) {
      elements.addAll(photosPath!.map((photo) => Image.file(File(photo))));
    }

    if (elements.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GridView.count(
          padding: const EdgeInsets.only(bottom: 16),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          mainAxisSpacing: 7,
          crossAxisCount: 1,
          children: elements.map((el) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FittedBox(
                clipBehavior: Clip.antiAlias,
                fit: BoxFit.cover,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black12),
                  child: el,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
