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


class CheckupHouseStepBuildingGasAndFireplaces extends StatefulWidget {
  final StepData step;
  final CheckupHouseCaseObject caseObject;
  const CheckupHouseStepBuildingGasAndFireplaces(this.step, this.caseObject, {super.key});

  @override
  State<CheckupHouseStepBuildingGasAndFireplaces> createState() => _CheckupHouseStepBuildingGasAndFireplacesState();
}

class _CheckupHouseStepBuildingGasAndFireplacesState extends State<CheckupHouseStepBuildingGasAndFireplaces> {

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
            'Открытый огонь в доме (камин, печь). Наличие газоснабжения, в т.ч. газовых баллонов.',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          const Text(
            'Минимум 2 фото на объект.',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          const Text(
            '1. Фото камина/печи с прилегающими станами, с предтопочным листом, дымоходами, вытяжными шахтами. Место стыка дымохода с потолком трубы отопления на каждом этаже.',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_gasAndFireplaces_01.jpg'),
          ),
          const SizedBox(height: 15),
          const Text(
            '2. Фото системы газоснабжения: магистраль, газгольдер, газовых баллонов и места их хранения.',
            style: TextStyle(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_gasAndFireplaces_02.jpg'),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusBig),
            child: Image.asset('assets/images/checkup_house/step_gasAndFireplaces_03.jpg'),
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
