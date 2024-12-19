import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko_bloc.dart';
import 'package:guideh/pages/checkup_kasko/photo_model.dart';
import 'package:guideh/pages/checkup_kasko/step_car_photos_do.dart';
import 'package:guideh/services/http.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum CarPhotoButtonStatus {
  empty, uploading, done, success, error
}

class CheckupKaskoCarPhotoButton extends StatefulWidget {
  final Alignment alignment;
  final String photoType;
  final CarPhotoButtonStatus status;
  final String? photoPath;
  final String parentId;
  const CheckupKaskoCarPhotoButton({
    super.key,
    required this.alignment,
    required this.photoType,
    required this.status,
    this.photoPath,
    required this.parentId,
  });

  CheckupKaskoCarPhotoButton loading() {
    return CheckupKaskoCarPhotoButton(
      alignment: alignment,
      photoType: photoType,
      status: CarPhotoButtonStatus.uploading,
      photoPath: photoPath,
      parentId: parentId,
    );
  }

  CheckupKaskoCarPhotoButton update(String? newPhotoPath) {
    if (newPhotoPath == null) {
      return this;
    }
    return CheckupKaskoCarPhotoButton(
      alignment: alignment,
      photoType: photoType,
      status: CarPhotoButtonStatus.done,
      photoPath: newPhotoPath,
      parentId: parentId,
    );
  }

  @override
  State<CheckupKaskoCarPhotoButton> createState() => _CheckupKaskoCarPhotoButtonState();
}

class _CheckupKaskoCarPhotoButtonState extends State<CheckupKaskoCarPhotoButton> {

  late Color bgColor;
  late Color iconColor;
  late IconData iconData;
  final double canvasSize = 85;
  final double buttonSize = 55;

  CarPhotoButtonStatus? updatedStatus;

  addPhoto(CheckupKaskoPhoto photo) async {

    setState(() => updatedStatus = CarPhotoButtonStatus.uploading);
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
      setState(() => updatedStatus = CarPhotoButtonStatus.error);
      return;
    }

    // ignore: use_build_context_synchronously
    var checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
    checkupKaskoBloc.add(CheckupKaskoAddCarPhoto(photo));
    setState(() => updatedStatus = CarPhotoButtonStatus.done);

  }

  @override
  Widget build(BuildContext context) {
    final status = updatedStatus ?? widget.status;

    switch (status) {
      case CarPhotoButtonStatus.empty:
      case CarPhotoButtonStatus.uploading:
        bgColor = const Color(0xffdfe1e7);
        iconColor = const Color(0xff959ba4);
        iconData = Icons.photo_camera;
        break;
      case CarPhotoButtonStatus.done:
        bgColor = const Color(0xffffb700);
        iconColor = const Color(0xffffffff);
        iconData = Icons.done;
        break;
      case CarPhotoButtonStatus.success:
        bgColor = const Color(0xffa2c116);
        iconColor = const Color(0xffffffff);
        iconData = Icons.done;
        break;
      case CarPhotoButtonStatus.error:
        bgColor = const Color(0xffe17661);
        iconColor = const Color(0xffffffff);
        iconData = Icons.error_outline;
        break;
    }

    Alignment counterAlignment =
      widget.alignment == Alignment.topLeft ? Alignment.bottomRight
      : widget.alignment == Alignment.topCenter ? Alignment.bottomCenter
      : widget.alignment == Alignment.topRight ? Alignment.bottomLeft
      : widget.alignment == Alignment.centerRight ? Alignment.centerLeft
      : widget.alignment == Alignment.bottomRight ? Alignment.topLeft
      : widget.alignment == Alignment.bottomCenter ? Alignment.topCenter
      : widget.alignment == Alignment.bottomLeft ? Alignment.topRight
      : widget.alignment == Alignment.centerLeft ? Alignment.centerRight
      : Alignment.center;

    return Align(
      alignment: widget.alignment,
      child: SizedBox(
        width: canvasSize,
        height: canvasSize,
        child: Stack(
          alignment: widget.alignment,
          children: [
            if (status == CarPhotoButtonStatus.empty || status == CarPhotoButtonStatus.error)
              Align(
                alignment: counterAlignment,
                child: CheckupKaskoCarPhotoButtonArrow(
                  color: bgColor,
                  size: buttonSize,
                  alignment: widget.alignment,
                ),
              ),
            Material(
              shape: const CircleBorder(),
              color: bgColor,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: IconButton(
                  icon: status == CarPhotoButtonStatus.uploading
                    ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Color(0xff959ba4),
                        strokeWidth: 3,
                      )
                    )
                    : Icon(iconData, size: 28),
                  color: iconColor,
                  onPressed: () async {
                    if (status == CarPhotoButtonStatus.success || status == CarPhotoButtonStatus.uploading) return;
                    final checkupKaskoBloc = BlocProvider.of<CheckupKaskoBloc>(context);
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CheckupKaskoStepCarPhotosDo(
                          photoType: widget.photoType,
                          addPhoto: addPhoto,
                          bloc: checkupKaskoBloc,
                        )
                    ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckupKaskoCarPhotoButtonArrow extends StatelessWidget {
  final Color color;
  final double size;
  final Alignment alignment;
  const CheckupKaskoCarPhotoButtonArrow({
    super.key,
    required this.color,
    required this.size,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    double angle =
      alignment == Alignment.topLeft ? 0
        : alignment == Alignment.topCenter ? (math.pi / 4)
        : alignment == Alignment.topRight ? (math.pi / 2)
        : alignment == Alignment.centerRight ? (math.pi * -5 / 4)
        : alignment == Alignment.bottomRight ? math.pi
        : alignment == Alignment.bottomCenter ? (math.pi * 5 / 4)
        : alignment == Alignment.bottomLeft ? (math.pi / -2)
        : alignment == Alignment.centerLeft ? (math.pi / -4)
        : 0;
    Offset offset =
      alignment == Alignment.topCenter ? const Offset(0, -10)
        : alignment == Alignment.centerRight ? const Offset(10, 0)
        : alignment == Alignment.bottomCenter ? const Offset(0, 10)
        : alignment == Alignment.centerLeft ? const Offset(-10, 0)
        : Offset.zero;
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: SvgPicture.string(rawSvg, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
      ),
    );
  }
}

const rawSvg = '''<svg width="51" height="51" viewBox="0 0 51 51" xmlns="http://www.w3.org/2000/svg"><path d="M3.06897 0.758179L0.978516 2.84849L45.9274 47.7984H36.2009V50.761H50.9785V35.9832L48.0159 35.9832V45.7058L3.06897 0.758179Z"/></svg>''';
