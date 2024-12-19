import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guideh/pages/checkup_house/models.dart';
import 'package:guideh/theme/theme.dart';

class CameraPhotosContainer extends StatefulWidget {
  final List<Photo>? photos;
  final List<String>? photosPath;
  final Widget? beforeWidget;
  final Widget? afterWidget;
  const CameraPhotosContainer({
    super.key,
    this.photos,
    this.photosPath,
    this.beforeWidget,
    this.afterWidget
  });

  @override
  State<CameraPhotosContainer> createState() => CameraPhotosContainerState();
}

class CameraPhotosContainerState extends State<CameraPhotosContainer> {

  late List<Photo> photos;
  late List<String> photosPath;

  @override
  void initState() {
    photos = widget.photos ?? [];
    photosPath = widget.photosPath ?? [];
    super.initState();
  }

  void addImage(String image) {
    setState(() => photosPath.add(image));
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> childWidgets = [];

    final beforeWidget = widget.beforeWidget;
    final afterWidget = widget.afterWidget;

    if (beforeWidget != null) {
      childWidgets.add(beforeWidget);
    }

    final List<Image> images = [
      // файлы в base64
      ...photos.map((photo) => Image.memory(base64Decode(photo.data))),
      // файлы в памяти телефона
      ...photosPath.map((photo) => Image.file(File(photo)))
    ];

    if (images.isNotEmpty) {
      childWidgets.add(
        GridView.builder(
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FittedBox(
                clipBehavior: Clip.antiAlias,
                fit: BoxFit.cover,
                child: images[index],
              ),
            );
          },
        ),
      );
    }

    if (afterWidget != null) {
      childWidgets.add(afterWidget);
    }

    return childWidgets.isNotEmpty
      ? Container(
        padding: const EdgeInsets.all(11),
        margin: const EdgeInsets.symmetric(vertical: 20),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xff373e46),
          borderRadius: BorderRadius.all(
              Radius.circular(borderRadiusBig)
          ),
        ),
        child: Column(
          children: childWidgets,
        ),
      )
    : const SizedBox.shrink();
  }

}
