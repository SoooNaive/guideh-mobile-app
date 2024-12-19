import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guideh/services/location.dart';

enum TakePhotoTemplate {
  passport,
  sts,
  driverLicenseFront,
  driverLicenseBack,
}

class TakePhoto extends StatefulWidget {
  final Function(String imagePath)? addPhoto;
  final Function(Position? location)? addPhotoLocation;
  final bool? locationRequired;
  final TakePhotoTemplate? template;

  const TakePhoto({
    super.key,
    required this.addPhoto,
    this.locationRequired,
    this.addPhotoLocation,
    this.template,
  });

  @override
  State<TakePhoto> createState() => _TakePhotoState();
}

class _TakePhotoState extends State<TakePhoto> {

  late Position? location;

  Future<CameraDescription?> getCamera() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // если необходимо определение местоположения
    if ((widget.locationRequired ?? false) != false) {
      try {
        location = await LocationService.get();
        if (location == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 5),
                content: Text('Не удалось определить местоположение. Повторите попытку.'),
                showCloseIcon: true,
                closeIconColor: Colors.white,
              ),
            );
          }
          return null;
        }
      } catch (e) {
        return null;
      }
    }

    WidgetsFlutterBinding.ensureInitialized();
    final cameras = await availableCameras();
    // final camera = cameras.first;
    final CameraDescription camera = cameras.firstWhere((item) => item.lensDirection == CameraLensDirection.back);
    return camera;
  }

  triggerAddPhotoLocation() {
    widget.addPhotoLocation!(location);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getCamera(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // не получили координаты
          if (snapshot.data == null) {
            Navigator.pop(context, false);
            return const SizedBox.shrink();
          }
          return TakePhotoScreen(
            camera: snapshot.data as CameraDescription,
            addPhoto: widget.addPhoto,
            triggerAddPhotoLocation: (widget.locationRequired ?? false) != false && (widget.addPhotoLocation != null)
              ? triggerAddPhotoLocation
              : null,
            template: widget.template,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}


class TakePhotoScreen extends StatefulWidget {
  final CameraDescription camera;
  final Function(String imagePath)? addPhoto;
  final Function()? triggerAddPhotoLocation;
  final TakePhotoTemplate? template;
  const TakePhotoScreen({
    super.key,
    required this.camera,
    required this.addPhoto,
    this.triggerAddPhotoLocation,
    this.template,
  });

  @override
  TakePhotoScreenState createState() => TakePhotoScreenState();
}

class TakePhotoScreenState extends State<TakePhotoScreen> {

  late Future<void> _initializeControllerFuture;
  late CameraController _controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void addPhoto(imagePath) {
    widget.addPhoto!(imagePath);
  }

  @override
  Widget build(BuildContext context) {

    String? templateRawSvg;
    String? templateCaption;
    switch (widget.template) {
      case TakePhotoTemplate.driverLicenseFront:
        templateCaption = 'Лицевая сторона ВУ';
        templateRawSvg = '''<svg width="1024" height="650" viewBox="0 0 1024 650" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="6" y="6" width="1012" height="638" rx="50" stroke="white" stroke-width="12"/>
          <rect x="58" y="144" width="264" height="361" rx="50" stroke="white" stroke-width="12"/>
          <ellipse cx="190" cy="304" rx="85" ry="113" stroke="white" stroke-width="12"/>
          </svg>
          ''';
        break;
      case TakePhotoTemplate.driverLicenseBack:
        templateCaption = 'Оборотная сторона ВУ';
        templateRawSvg = '''<svg width="1024" height="650" viewBox="0 0 1024 650" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="6" y="6" width="1012" height="638" rx="50" stroke="white" stroke-width="12"/>
          </svg>
          ''';
        break;
      case TakePhotoTemplate.passport:
        templateCaption = 'Разворот паспорта с фотографией';
        templateRawSvg = '''<svg width="757" height="1059" viewBox="0 0 757 1059" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="38" y="637" width="209" height="261" rx="15" stroke="white" stroke-width="12"/>
          <ellipse cx="142.5" cy="768" rx="63.5" ry="84" stroke="white" stroke-width="12"/>
          <rect x="6" y="6" width="745" height="1047" rx="20" stroke="white" stroke-width="12"/>
          <path d="M6 530H751" stroke="white" stroke-width="12" stroke-linecap="square"/>
          </svg>
          ''';
        break;
      case TakePhotoTemplate.sts:
        templateCaption = 'Лицевая сторона СТС\n(с VIN-номером)';
        templateRawSvg = '''<svg width="761" height="1060" viewBox="0 0 761 1060" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="6" y="6" width="749" height="1048" rx="14" stroke="white" stroke-width="12"/>
          <path d="M755 61H90C85.5817 61 82 64.5817 82 69V103C82 107.418 85.5817 111 90 111H755" stroke="white" stroke-width="12"/>
          <path d="M82 158H674" stroke="white" stroke-width="12" stroke-linecap="round"/>
          <path d="M125 203H631" stroke="white" stroke-width="12" stroke-linecap="round"/>
          </svg>
          ''';
        break;
      case null:
        templateCaption = null;
        templateRawSvg = null;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Сделайте фото')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return (widget.template == null)
              ? CameraPreview(_controller)
              : Stack(
                children: [
                  CameraPreview(_controller),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 35,
                        horizontal: 25
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black.withAlpha(200),
                          ),
                          child: Text(
                            templateCaption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                            textAlign: TextAlign.center
                          ),
                        ),
                        Flexible(child: SvgPicture.string(templateRawSvg!)),
                      ],
                    ),
                  ),
                ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      backgroundColor: Colors.black12,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : () async {
          setState(() => isLoading = true);

          await _initializeControllerFuture;
          final image = await _controller.takePicture();
          if (!context.mounted) return;

          final bool? confirmPhotoScreenReturn = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConfirmPhotoScreen(
                imagePath: image.path,
                addPhotoPath: addPhoto,
              ),
            ),
          );

          // подтвердили сделанное фото
          if (confirmPhotoScreenReturn == true && context.mounted) {
            if (widget.triggerAddPhotoLocation != null) widget.triggerAddPhotoLocation!();
            Navigator.pop(context, true);
          }
          else {
            setState(() => isLoading = false);
          }

        },
        child: isLoading
          ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          )
          : const Icon(Icons.camera_alt),
      ),
    );
  }
}

class ConfirmPhotoScreen extends StatefulWidget {
  final String imagePath;
  final Function(String) addPhotoPath;

  const ConfirmPhotoScreen({
    super.key,
    required this.imagePath,
    required this.addPhotoPath,
  });

  @override
  State<ConfirmPhotoScreen> createState() => _ConfirmPhotoScreenState();
}

class _ConfirmPhotoScreenState extends State<ConfirmPhotoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтвердите фото')),
      body: Image.file(File(widget.imagePath)),
      backgroundColor: Colors.black12,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                Navigator.pop(context, false);
              },
              backgroundColor: Colors.black54,
              label: const Text('Переснять'),
            ),
            FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                widget.addPhotoPath(widget.imagePath);
                Navigator.pop(context, true);
              },
              label: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }
}
