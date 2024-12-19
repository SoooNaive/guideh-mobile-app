import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/photo_model.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/functions.dart';

class CheckupKaskoStepCarPhotosDo extends StatefulWidget {
  final String photoType;
  final Function(CheckupKaskoPhoto photo) addPhoto;
  final CheckupKaskoBloc bloc;
  const CheckupKaskoStepCarPhotosDo({
    super.key,
    required this.addPhoto,
    required this.photoType,
    required this.bloc,
  });

  @override
  State<CheckupKaskoStepCarPhotosDo> createState() => _CheckupKaskoStepCarPhotosDoState();
}

class _CheckupKaskoStepCarPhotosDoState extends State<CheckupKaskoStepCarPhotosDo> {

  Color activeColor = const Color(0xffffb700);
  double carPhotoScale = 0.85;

  String? photoPath;
  Position? location;

  void addPhoto(String imagePath) {
    setState(() => photoPath = imagePath);
    if (location != null) returnPhoto();
  }

  void addPhotoLocation(Position? imageLocation) {
    setState(() => location = imageLocation);
    if (photoPath != null) returnPhoto();
  }

  void returnPhoto() {
    widget.addPhoto(CheckupKaskoPhoto(
      path: photoPath!,
      type: widget.photoType,
      latitude: location!.latitude,
      longitude: location!.longitude,
    ));
    Navigator.pop(context);
  }

  @override
  initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 0)).then((value) {
      setState(() {
        carPhotoScale = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    String? hasPhotoPath;
    String? img;
    String text;
    switch (widget.photoType) {
      case '0': text = 'спереди-слева'; img = 'car-top-left.png'; break;
      case '1': text = 'спереди'; img = 'car-top.png'; break;
      case '2': text = 'спереди-справа'; img = 'car-top-right.png'; break;
      case '3': text = 'правый бок'; img = 'car-right.png'; break;
      case '4': text = 'сзади-справа'; img = 'car-bottom-right.png'; break;
      case '5': text = 'сзади'; img = 'car-bottom.png'; break;
      case '6': text = 'сзади-слева'; img = 'car-bottom-left.png'; break;
      case '7': text = 'левый бок'; img = 'car-left.png'; break;
      default: text = 'сделайте фото'; break;
    }

    final hasPhotoIndex = widget.bloc.state.carPhotos.indexWhere((photo) {
      return photo.type == widget.photoType;
    });
    if (hasPhotoIndex >= 0) {
      hasPhotoPath = widget.bloc.state.carPhotos[hasPhotoIndex].path;
    }

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => exitCheckupDialog(context),
          icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
        ),
        title: const Text('КАСКО Самоосмотр'),
      ),

      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.fromLTRB(10, 30, 10, 0),
            decoration: BoxDecoration(
              border: Border.all(
                color: activeColor,
                width: 4,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 9),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          Expanded(
            child: Stack(
              children: [

                Center(
                  child: GestureDetector(
                    onTap: () => _makePhoto(),
                    child: hasPhotoPath != null
                      ? SizedBox(
                        height: 290,
                        width: double.infinity,
                        child: Image.file(
                          File(hasPhotoPath),
                          color: const Color(0x50000000),
                          colorBlendMode: BlendMode.darken,
                          fit: BoxFit.cover,
                        )
                      )
                      : img != null
                        ? AnimatedScale(
                          scale: carPhotoScale,
                          duration: const Duration(seconds: 30),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          child: Image.asset('assets/images/checkup_kasko/$img'),
                        )
                        : Text('Сделайте фото ($text)')
                  ),
                ),

                const PhotoBorderCorners(),

              ],
            ),
          ),

          SizedBox(
            height: 55,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.pop(false),
                    child: Container(
                      color: const Color(0xffedeff2),
                      child: const Icon(
                        Icons.keyboard_backspace,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _makePhoto(),
                    child: Container(
                      color: activeColor,
                      child: const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),

    );
  }

  void _makePhoto() async {
    setState(() {
      photoPath = null;
      location = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePhoto(
          addPhoto: addPhoto,
          addPhotoLocation: addPhotoLocation,
          locationRequired: true,
        ),
      )
    );
  }

}

class PhotoBorderCorners extends StatelessWidget {
  const PhotoBorderCorners({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 230,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: SvgPicture.asset('assets/images/checkup_kasko/car-photo-lense-corner-1.svg'),
            ),
            Align(
              alignment: Alignment.topRight,
              child: SvgPicture.asset('assets/images/checkup_kasko/car-photo-lense-corner-2.svg'),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: SvgPicture.asset('assets/images/checkup_kasko/car-photo-lense-corner-3.svg'),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: SvgPicture.asset('assets/images/checkup_kasko/car-photo-lense-corner-4.svg'),
            ),
          ],
        ),
      ),
    );
  }
}
