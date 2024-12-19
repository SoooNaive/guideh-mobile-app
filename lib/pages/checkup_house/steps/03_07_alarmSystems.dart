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


class CheckupHouseStepBuildingAlarmSystems extends StatefulWidget {
  final StepData step;
  final CheckupHouseCaseObject caseObject;
  const CheckupHouseStepBuildingAlarmSystems(this.step, this.caseObject, {super.key});

  @override
  State<CheckupHouseStepBuildingAlarmSystems> createState() => _CheckupHouseStepBuildingAlarmSystemsState();
}

class _CheckupHouseStepBuildingAlarmSystemsState extends State<CheckupHouseStepBuildingAlarmSystems> {

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
        children: [
          MyTitle(widget.step.title),
          const Text(
            'Фото охранной/пожарной систем (при наличии). Минимум по одной фото (датчик, пульт, кнопки и т.д.)',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          const Text(
            '- фото охранной системы (датчики, пульт),\n'
            '- фото противопожарной системы (датчики, пульт, кнопка),\n'
            '- фото автоматической системы пожаротушения.\n',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_alarmSystems_01.jpg'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
