import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/camera_photos_container.dart';
import 'package:guideh/layout/my_title.dart';
import 'package:guideh/pages/checkup_house/functions.dart';
import 'package:guideh/pages/checkup_house/models.dart';
import 'package:guideh/pages/checkup_house/step_scaffold.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/theme/theme.dart';


class CheckupHouseStepBuildingEngineeringEquipment extends StatefulWidget {
  final StepData step;
  final CheckupHouseCaseObject caseObject;
  const CheckupHouseStepBuildingEngineeringEquipment(this.step, this.caseObject, {super.key});

  @override
  State<CheckupHouseStepBuildingEngineeringEquipment> createState() => _CheckupHouseStepBuildingEngineeringEquipmentState();
}

class _CheckupHouseStepBuildingEngineeringEquipmentState extends State<CheckupHouseStepBuildingEngineeringEquipment> {

  final bool isBuildingStep = true;
  final GlobalKey<CameraPhotosContainerState> _imagesContainer = GlobalKey();

  void addPhoto(String imagePath) {
    _imagesContainer.currentState?.addImage(imagePath);
    // скроллим вниз
    WidgetsBinding.instance.addPostFrameCallback((_) => Scrollable.ensureVisible(
      _imagesContainer.currentContext!,
      duration: const Duration(milliseconds: 400),
    ));
  }

  void addPhotoLocation(Position? location) {
    widget.caseObject.photosPathLocation ??= <Position>[];
    widget.caseObject.photosPathLocation?.add(location);
  }

  @override
  void initState() {
    updateBuildingStepObjectValidity(widget.step, widget.caseObject);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final steps = isBuildingStep ? stepsBuilding : stepsMain;
    final int stepIndex = steps.indexWhere((step) => step.type == widget.step.type);
    final stepContent = CheckupHouseStepContent(

      title: getStepScaffoldTitle(isBuildingStep, stepIndex, widget.caseObject.parent),

      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyTitle(widget.step.title),
          const Text(
            'Стационарно установленные внутри этого дома или расположенные за его пределами, но при этом установленные стационарно и обеспечивающие работу инженерного оборудования внутри этого строения элементы систем (приборы/объекты):',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          Text([
            '— вентиляции,',
            '— холодного и горячего водоснабжения, включая бойлеры, водонагреватели, котлы электрические/газовые/твердотопливаные, баки, термостаты и другие элементы таких систем, обеспечивающих подачу воды для ее потребления в бытовых целях, исключая стиральные, посудомоечные машины и иные устройства, являющиеся самостоятельными потребителями воды,',
            '— санитарно-техническое оборудование: смесители, краны, вентили, раковины, ванны, душевые кабины, унитазы, сливные бачки, биде и др.',
            '— канализации;',
            '— отопления (включая радиаторы),',
            '— кондиционирования воздуха (вентиляционные каналы, включая кондиционеры, внешние и внутренние навесные блоки и прочую технику),',
            '— встроенного искусственного освещения;',
            '— напольные газовые плиты, газовые колонки,',
            '— подогрева полов;',
            '— счетчики воды и газа;',
            '— электроснабжения, включая электропроводку, распределительные щиты;',
            '— телефонной, телевизионной, радио или иной связи;',
            '— предметы, закрепленные на наружной стороне объекта капитального строительства: комплекты эфирного или спутникового телевидения; оборудование, относящееся к системам кондиционирования, системы видеонаблюдения, контроля доступа, охранного телевидения, и т.п.',
            ].toList().join('\n'),
            style: const TextStyle(fontSize: 14, height: 1.25),
          ),
          const SizedBox(height: 15),
          const Text(
            'Каждого оборудования минимум по одной фото (общий вид, марку/модель)',
            style: TextStyle(fontSize: 14, height: 1.25),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_engineeringEquipment_01.jpg'),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_engineeringEquipment_02.jpg'),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_engineeringEquipment_03.jpg'),
          ),
          const SizedBox(height: 15),
          CameraPhotosContainer(
            key: _imagesContainer,
            photosPath: widget.caseObject.photosPath,
            photos: widget.caseObject.photos,
          ),
        ],
      ),

      bottom: Column(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Добавить фото'),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakePhoto(
                      addPhoto: addPhoto,
                      addPhotoLocation: addPhotoLocation,
                      locationRequired: true,
                    ),
                  )
              );
            },
            style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.library_add_check_outlined),
            label: const Text('Все фото добавлены'),
            onPressed: () async {
              await goNextStepDialog(context,
                  minPhotos: widget.step.minPhotos,
                  stepPhotosCount: widget.caseObject.photosCount
              ) ? context.pop(true) : null;
            },
            style: getTextButtonStyle(TextButtonStyle()),
          ),
          if (Platform.isIOS) const SizedBox(height: 12),
        ],
      ),

    );

    return checkupHouseStepBuilder(context, stepContent);

  }

}
