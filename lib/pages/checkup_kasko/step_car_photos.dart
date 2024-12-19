import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/photo_button.dart';
import 'package:guideh/pages/checkup_kasko/alert.dart';
import 'package:guideh/services/functions.dart';
import 'package:collection/collection.dart';

import 'photo_model.dart';


class CheckupKaskoStepCarPhotos extends StatefulWidget {
  final Function(String stepName)? goToNextStepFrom;
  final String parentId;
  const CheckupKaskoStepCarPhotos({
    super.key,
    this.goToNextStepFrom,
    required this.parentId,
  });

  @override
  State<CheckupKaskoStepCarPhotos> createState() => _CheckupKaskoStepCarPhotosState();
}

class _CheckupKaskoStepCarPhotosState extends State<CheckupKaskoStepCarPhotos> {

  bool showAlert = true;
  double alertOpacity = 1;
  double contentOpacity = 0;
  double contentCarOpacity = 0;
  late CheckupKaskoBloc checkupKaskoBloc;
  late StreamSubscription<CheckupKaskoState> checkupKaskoBlocStream;
  late int approvedPhotosLength;

  void _closeAlert() async {
    setState(() => alertOpacity = 0);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      showAlert = false;
      contentOpacity = 1;
      approvedPhotosLength = checkupKaskoBloc.state.casePhotos.where((photo) {
        return photo.check == '1' && ['0','1','2','3','4','5','6','7'].contains(photo.type);
      }).length;
    });
  }

  _goToNextStep() {
    if (widget.goToNextStepFrom != null) {
      widget.goToNextStepFrom!('car_photos');
    }
    else {
      print('Ошибка: не передана goToNextStepFrom()');
    }
  }

  @override
  void initState() {
    checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
    checkupKaskoBlocStream = checkupKaskoBloc.stream.listen((event) {
      // проверяем каждый раз после добавления фотки
      if (event.loadingPhotoDone == true) {
        // залили + одобрено = все 8 фоток → идём дальше
        if (event.carPhotos.length + approvedPhotosLength >= 8) {
          _goToNextStep();
        }
        else {
          checkupKaskoBloc.add(CheckupKaskoResetPhotoDone());
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    checkupKaskoBlocStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => exitCheckupDialog(context),
          icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
        ),
        title: const Text('КАСКО Самоосмотр'),
      ),

      body: showAlert

        // экран-предупреждение
        ? AnimatedOpacity(
          opacity: alertOpacity,
          duration: const Duration(milliseconds: 650),
          child: CheckupKaskoAlert(
            closeAlert: _closeAlert,
            iconData: Icons.warning_amber_rounded,
            text: 'Осмотр должен производиться чистой машины, в светлое время суток или в светлом помещении',
            textCloseAlert: 'Продолжить',
          ),
        )

        // экран основной с машинкой
        : AnimatedOpacity(
          opacity: contentOpacity,
          duration: const Duration(milliseconds: 500),
          child: showData(),
          onEnd: () async {
            await Future.delayed(const Duration(milliseconds: 650));
            setState(() => contentCarOpacity = 1);
          },
        ),

    );
  }


  Widget showData() {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15
          ),
          decoration: const BoxDecoration(
            color: Color(0xffe7e9ee),
          ),
          child: const Text(
            'Сфотографируйте ТС со всех ракурсов',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedOpacity(
              opacity: contentCarOpacity,
              duration: const Duration(milliseconds: 650),
              child: BlocBuilder(
                bloc: CheckupKaskoBloc(),
                builder: (context, state) {

                  final List<CheckupKaskoPhoto> casePhotos = checkupKaskoBloc.state.casePhotos;

                  Map<String, CarPhotoButtonStatus> statuses = {};
                  for (String type in ['0','1','2','3','4','5','6','7']) {
                    final String? photoCheck =
                      casePhotos.firstWhereOrNull((photo) => photo.type == type)?.check;
                    if (photoCheck == '0') {
                      statuses[type] = CarPhotoButtonStatus.error;
                    } else if (photoCheck == '1') {
                      statuses[type] = CarPhotoButtonStatus.success;
                    } else {
                      statuses[type] = CarPhotoButtonStatus.empty;
                    }
                  }

                  return Stack(
                    children: [

                      // машинка
                      Center(
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.4
                            ),
                            child: Image.asset('assets/images/checkup_kasko/car.png')
                        ),
                      ),

                      // кнопки-фотки
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.topLeft,
                        photoType: '0',
                        status: statuses['0'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.topCenter,
                        photoType: '1',
                        status: statuses['1'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.topRight,
                        photoType: '2',
                        status: statuses['2'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.centerRight,
                        photoType: '3',
                        status: statuses['3'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.bottomRight,
                        photoType: '4',
                        status: statuses['4'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.bottomCenter,
                        photoType: '5',
                        status: statuses['5'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.bottomLeft,
                        photoType: '6',
                        status: statuses['6'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),
                      CheckupKaskoCarPhotoButton(
                        alignment: Alignment.centerLeft,
                        photoType: '7',
                        status: statuses['7'] ?? CarPhotoButtonStatus.empty,
                        parentId: widget.parentId,
                      ),

                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

