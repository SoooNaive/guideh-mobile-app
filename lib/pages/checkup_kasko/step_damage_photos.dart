import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guideh/layout/camera_photos_container.dart';
import 'package:guideh/pages/checkup_kasko/alert.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/photo_model.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckupKaskoStepDamagePhotos extends StatefulWidget {
  final Function(String stepName) goToNextStepFrom;
  final String parentId;
  const CheckupKaskoStepDamagePhotos({
    super.key,
    required this.goToNextStepFrom,
    required this.parentId,
  });

  @override
  State<CheckupKaskoStepDamagePhotos> createState() => _CheckupKaskoStepDamagePhotosState();
}

class _CheckupKaskoStepDamagePhotosState extends State<CheckupKaskoStepDamagePhotos> {

  bool showAlert = true;
  double alertOpacity = 1;
  double contentOpacity = 0;
  double contentCarOpacity = 0;

  void _closeAlert() async {
    setState(() => alertOpacity = 0);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      showAlert = false;
      contentOpacity = 1;
    });
  }

  void _goToNextStep() async {
    setState(() {
      contentOpacity = 0;
      alertOpacity = 0;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    widget.goToNextStepFrom('damage_photos');
  }

  // фотки

  String? photoPath;
  Position? location;
  bool isLoading = false;

  void addPhoto(String imagePath) {
    setState(() => photoPath = imagePath);
    if (location != null) returnPhoto();
  }

  void addPhotoLocation(Position? imageLocation) {
    setState(() => location = imageLocation);
    if (photoPath != null) returnPhoto();
  }

  void returnPhoto() async {

    setState(() => isLoading = true);
    _imagesContainer.currentState?.addImage(photoPath!);
    final checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);

    final photo = CheckupKaskoPhoto(
      path: photoPath!,
      type: 'damage_${checkupKaskoBloc.state.damagePhotos.length}',
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
    );

    SharedPreferences preferences = await SharedPreferences.getInstance();

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
    else {
      checkupKaskoBloc.add(CheckupKaskoAddDamagePhoto(photo));
    }

    setState(() {
      isLoading = false;
      photoPath = null;
      location = null;
    });
  }

  final GlobalKey<CameraPhotosContainerState> _imagesContainer = GlobalKey();

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
          iconData: Icons.done,
          text: 'Готово. Теперь сделайте фото сколов, вмятин и повреждений кузова.',
          textCloseAlert: 'Загрузить фотографии',
          extraButtons: [
            TextButton(
              style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
              onPressed: _goToNextStep,
              child: const Text('Повреждений нет'),
            ),
          ],
        ),
      )

      // контент
      : AnimatedOpacity(
        opacity: contentOpacity,
        duration: const Duration(milliseconds: 500),
        child: showData(),
        onEnd: () async {
          await Future.delayed(const Duration(milliseconds: 450));
          if (context.mounted) {
            setState(() => contentCarOpacity = 1);
          }
        },
      ),

    );
  }

  Widget showData() {

    final checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
    final List<CheckupKaskoPhoto> photos = checkupKaskoBloc.state.damagePhotos;

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
            'Загрузите фото повреждений',
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
              child: Column(
                children: [

                  Expanded(
                    child: photos.isNotEmpty
                      ? Stack(
                        children: [
                          Opacity(
                            opacity: isLoading ? 0.15 : 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CameraPhotosContainer(
                                  key: _imagesContainer,
                                  photosPath: photos.map((el) => el.path!).toList(),
                                )
                              ],
                            ),
                          ),
                          if (isLoading) const Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(color: Colors.black54),
                          )
                        ],
                      )
                      : isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.black54))
                        : const Center(child: Text('Нет загруженных фото')),
                  ),

                  TextButton.icon(
                    style: getTextButtonStyle(),
                    onPressed: () {
                      if (isLoading) return;
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
                    label: const Text(
                      'Добавить фотографию',
                      textAlign: TextAlign.center,
                    ),
                    icon: const Icon(Icons.photo_camera, size: 20),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton(
                      style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                      onPressed: isLoading ? null : _goToNextStep,
                      child: const Text(
                        'Добавлены фото всех повреждений',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}
