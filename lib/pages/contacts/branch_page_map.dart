import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'models/branch.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';


class BranchPageMap extends StatefulWidget {
  final Branch branch;
  const BranchPageMap({super.key, required this.branch});

  @override
  State<BranchPageMap> createState() => _BranchPageMapState();
}

class _BranchPageMapState extends State<BranchPageMap> {

  late YandexMapController controller;
  GlobalKey mapKeyBranch = GlobalKey();

  // Future<bool> get locationPermissionNotGranted async => !(await Permission.location.request().isGranted);

  final animation = const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      key: mapKeyBranch,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())
      },
      mapObjects: [
        PlacemarkMapObject(
          mapId: MapObjectId(widget.branch.id),
          point: Point(
            latitude: double.parse(widget.branch.xCoordinates),
            longitude: double.parse(widget.branch.yCoordinates)
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/images/placemark.png'),
              zIndex: 1,
              scale: 0.85,
              rotationType: RotationType.noRotation
            )
          ),
          opacity: 1,
        )
      ],
      onMapCreated: (YandexMapController yandexMapController) async {
        controller = yandexMapController;
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(
                latitude: double.parse(widget.branch.xCoordinates),
                longitude: double.parse(widget.branch.yCoordinates)
              ),
              zoom: 14
            )
          ),
          // animation: animation
        );
      },
    );
  }
}
