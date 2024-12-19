import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guideh/pages/checkup_kasko/alert.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/photo_model.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckupKaskoStepExtraPhotos extends StatefulWidget {
  final Function(String stepName) goToNextStepFrom;
  final String parentId;
  final bool stepHasDeniedPhotos;
  const CheckupKaskoStepExtraPhotos({
    super.key,
    required this.goToNextStepFrom,
    required this.parentId,
    required this.stepHasDeniedPhotos,
  });

  @override
  State<CheckupKaskoStepExtraPhotos> createState() => _CheckupKaskoStepExtraPhotosState();
}


class _CheckupKaskoStepExtraPhotosState extends State<CheckupKaskoStepExtraPhotos> with TickerProviderStateMixin {

  late CheckupKaskoBloc checkupKaskoBloc;
  late StreamSubscription<CheckupKaskoState> checkupKaskoBlocStream;
  late int approvedPhotosLength;

  late final AnimationController _alertController = AnimationController(
    duration: const Duration(milliseconds: 650),
    vsync: this,
  )..forward();
  late final Animation<double> _alertAnimation = CurvedAnimation(
    parent: _alertController,
    curve: Curves.linear,
  );

  late final AnimationController _contentController = AnimationController(
    duration: const Duration(milliseconds: 650),
    vsync: this,
  );
  late final Animation<double> _contentAnimation = CurvedAnimation(
    parent: _contentController,
    curve: Curves.linear,
  );

  @override
  void initState() {
    checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
    checkupKaskoBlocStream = checkupKaskoBloc.stream.listen((event) {
      // проверяем каждый раз после добавления фотки
      if (event.loadingPhotoDone == true) {
        // залили + одобрено = все фотки → идём дальше
        if (event.extraPhotos.length + approvedPhotosLength >= extraPhotosData.length) {
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
    _alertController.dispose();
    _contentController.dispose();
    checkupKaskoBlocStream.cancel();
    super.dispose();
  }

  bool showAlert = true;

  void _closeAlert() async {
    _alertController.reverse();
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      final List<String> extraTypes = extraPhotosData.map((item) => item['name'] ?? '').toList();
      approvedPhotosLength = checkupKaskoBloc.state.casePhotos.where((photo) {
        return photo.check == '1' && extraTypes.contains(photo.type);
      }).length;
      showAlert = false;
      _contentController.forward();
    });
  }

  List<bool> photosValidity = List.generate(extraPhotosData.length, (i) => true);
  List<bool> photosLoading = List.generate(extraPhotosData.length, (i) => false);

  void _goToNextStep() => widget.goToNextStepFrom('extra_photos');

  String? photoPath;
  Position? location;
  int? photoIndex;

  void addPhoto(String imagePath) {
    setState(() => photoPath = imagePath);
    if (location != null) returnPhoto();
  }

  void addPhotoLocation(Position? imageLocation) {
    setState(() => location = imageLocation);
    if (photoPath != null) returnPhoto();
  }

  void returnPhoto() async {

    if (photoIndex != null) setState(() => photosLoading[photoIndex!] = true);

    SharedPreferences preferences = await SharedPreferences.getInstance();
    // ignore: use_build_context_synchronously
    final checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);

    final photo = CheckupKaskoPhoto(
      path: photoPath!,
      type: extraPhotosData[photoIndex!]['name'] ?? '',
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
    );

    final saveResponse = await Http.mobApp(
      ApiParams('Checkup', 'FileSave', {
        'Phone': preferences.getString('phone') ?? '',
        'PolisId': widget.parentId,
        'File': jsonDecode(jsonEncode(photo)),
      })
    );

    if (!saveResponse.containsKey('DocId') || saveResponse['Error'].length > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки фотографии. Попробуйте ещё раз или обратитесь в поддержку.')),
        );
      }
      return;
    }

    await preferences.setString('draftKaskoCheckupId', saveResponse['DocId']);
    checkupKaskoBloc.add(CheckupKaskoAddExtraPhoto(photo));
    setState(() {
      if (photoIndex != null) setState(() => photosLoading[photoIndex!] = false);
      photoPath = null;
      location = null;
      photoIndex = null;
    });

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
      ? FadeTransition(
        opacity: _alertAnimation,
        child: CheckupKaskoAlert(
          closeAlert: _closeAlert,
          iconData: widget.stepHasDeniedPhotos ? null :Icons.done,
          text: widget.stepHasDeniedPhotos
              ? 'Необходимо сделать новые фотографии'
              : 'Теперь сделайте дополнительные фотографии',
          textCloseAlert: 'Какие?',
        ),
      )

      // контент
      : FadeTransition(
        opacity: _contentAnimation,
        child: showData(),
      ),

    );
  }

  Widget showData() {
    return BlocBuilder(
      bloc: CheckupKaskoBloc(),
      builder: (context, state) {
        final checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
        final List<CheckupKaskoPhoto> casePhotos = checkupKaskoBloc.state.casePhotos;
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
                'Сделайте фотографии:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                    physics: const ScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: extraPhotosData.length,
                    itemBuilder: (BuildContext context, int index) {
                      final button = extraPhotosData[index];
                      final String photoType = button['name']!;
                      final bool isLoading = photosLoading[index];
                      final bool isLoaded = checkupKaskoBloc.state.extraPhotos.any((loadedPhoto) {
                        return loadedPhoto.type == photoType;
                      });

                      bool isSuccess;
                      bool isError;

                      if (casePhotos.isNotEmpty) {
                        final String? photoCheck = casePhotos.firstWhereOrNull(
                          (photo) => photo.type == photoType
                        )?.check;
                        isSuccess = photoCheck == '1';
                        isError = photoCheck == '0';
                      }
                      else {
                        isSuccess = false;
                        isError = false;
                      }

                      const doneColor = Color(0xfff7b200);
                      const successColor = Color(0xffa2c116);
                      const errorColor = Color(0xffe17661);

                      final Color color = isSuccess
                        ? successColor
                        : isError
                          ? errorColor
                          : photosValidity[index]
                            ? Colors.grey
                            : errorColor;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: TextButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSuccess || isError || isLoaded
                              ? Colors.white
                              : color,
                            backgroundColor: isSuccess
                              ? successColor
                              : isLoaded
                                ? doneColor
                                : isError
                                  ? errorColor
                                  : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: isLoaded ? doneColor : color.withAlpha(160),
                              width: 3,
                            ),
                            minimumSize: const Size.fromHeight(52),
                            alignment: Alignment.center,
                            textStyle: TextStyle(
                              color: isLoaded ? Colors.white : color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () async {
                            if (photoIndex != null) return;
                            if (isSuccess || isLoading) return;
                            setState(() => photoIndex = index);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            final bool? takePhotoAnswer = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePhoto(
                                    addPhoto: addPhoto,
                                    addPhotoLocation: addPhotoLocation,
                                    locationRequired: true,
                                  ),
                                )
                            );
                            // если попнулось без фотки
                            if ((takePhotoAnswer ?? false) == false) {
                              setState(() => photoIndex = null);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(button['title'] ?? ''),
                                    if (isLoaded || isSuccess || isError) Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isError && !isLoaded ? Icons.error_outline : Icons.done,
                                            size: 14
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              isError && !isLoaded ? 'Необходимо загрузить новое фото' : 'Загружено',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 12
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              if (isLoading) SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: isLoaded || isError ? Colors.white : Colors.grey,
                                ),
                              ),
                              if (isSuccess) const Icon(
                                Icons.done_all,
                                color: Colors.white,
                              ),
                              if (isError && !isLoaded && !isLoading) const Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                              ),
                              if (isLoaded) Icon(
                                Icons.photo_camera,
                                color: isLoaded ? Colors.white : color,
                              ),
                            ],
                          ),

                        ),
                      );
                    }
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 7,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      style: getTextButtonStyle(),
                      onPressed: () {
                        if (photosLoading.any((el) => el)) return;
                        if (checkupKaskoBloc.state.extraPhotos.length == extraPhotosData.length) {
                          _goToNextStep();
                          return;
                        }

                        // валидация
                        List<bool> newPhotosValidity = [];
                        for (var photo in extraPhotosData) {
                          final bool isValid = checkupKaskoBloc.state.extraPhotos.any((loadedPhoto) {
                            return loadedPhoto.type == photo['name'];
                          });
                          newPhotosValidity.add(isValid);
                        }
                        setState(() => photosValidity = newPhotosValidity);

                      },
                      child: const Text('Продолжить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

}
