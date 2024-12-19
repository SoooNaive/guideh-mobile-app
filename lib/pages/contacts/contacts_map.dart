import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/location.dart';
import 'package:guideh/theme/theme.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'models/branch.dart';
import 'api_data.dart';


class ContactsMapPage extends StatefulWidget {
  const ContactsMapPage({super.key});

  @override
  ContactsMapPageState createState() => ContactsMapPageState();
}

class ContactsMapPageState extends State<ContactsMapPage> with AutomaticKeepAliveClientMixin<ContactsMapPage> {

  @override
  bool get wantKeepAlive => true;

  String userCityId = '1';
  bool showLocationButton = false;
  Point? userLocationPoint;

  GlobalKey mapKey = GlobalKey();
  late List<MapObject> mapObjects = [];
  late YandexMapController controller;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dpi = MediaQuery.of(context).devicePixelRatio;

    return FutureBuilder(
      future: ApiData().getBranches(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text('Загрузка карты'),
              ],
            ),
          );
        }
        else {

          final List<Branch> branches = snapshot.data;

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              YandexMap(
                key: mapKey,
                mapObjects: mapObjects,
                // focusRect: const ScreenRect(topLeft: ScreenPoint(x: 29, y: 60), bottomRight: ScreenPoint(x: 29, y: 61)),
                onMapCreated: (YandexMapController yandexMapController) async {
                  controller = yandexMapController;

                  var userCityView = getPointOfCity(userCityId);
                  controller.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: Point(latitude: userCityView[0], longitude: userCityView[1]),
                        zoom: userCityView[2]
                      )
                    ),
                  );

                  // * цикл

                  List<PlacemarkMapObject> allMapObjects = [];
                  for (var i = 0; i < branches.length; i++) {
                    Branch branch = branches[i];
                    if (branch.xCoordinates != '' && branch.yCoordinates != '') {
                      allMapObjects.add(
                        PlacemarkMapObject(
                          mapId: MapObjectId(branch.id),
                          point: Point(
                            latitude: double.parse(branch.xCoordinates),
                            longitude: double.parse(branch.yCoordinates)
                          ),
                          icon: PlacemarkIcon.single(
                            PlacemarkIconStyle(
                              image: BitmapDescriptor.fromAssetImage('assets/images/placemark.png'),
                              zIndex: 1,
                              scale: dpi * 0.35,
                              rotationType: RotationType.noRotation
                            )
                          ),
                          opacity: 1,
                          onTap: (PlacemarkMapObject self, Point point) => onTapBranch(branch),
                          consumeTapEvents: true,
                        )
                      );
                    }
                  }
                  setState(() => mapObjects.addAll(allMapObjects));

                  // определяем местоположение

                  // крэшится на этой строке - заменили на geolocator
                  // await controller.toggleUserLayer(visible: true);
                  // final userPosition = await controller.getUserCameraPosition();
                  // if (userPosition != null) {
                  //   CameraPosition zoomedUserPosition = CameraPosition(target: userPosition.target, zoom: 13);
                  //   await controller.moveCamera(
                  //       CameraUpdate.newCameraPosition(zoomedUserPosition),
                  //   );
                  // }

                  final location = await LocationService.get();
                  if (location != null) {
                    setState(() => userLocationPoint = Point(
                      latitude: location.latitude,
                      longitude: location.longitude
                    ));
                    mapObjects.removeWhere((el) => el.mapId.value == 'user');
                    mapObjects.add(
                      PlacemarkMapObject(
                        mapId: const MapObjectId('user'),
                        point: userLocationPoint!,
                        icon: PlacemarkIcon.single(
                            PlacemarkIconStyle(
                                image: BitmapDescriptor.fromAssetImage('assets/images/placemark-user.png'),
                                zIndex: 2,
                                scale: dpi * 0.35,
                                rotationType: RotationType.noRotation
                            )
                        ),
                        opacity: 1,
                      )
                    );

                    Timer(const Duration(milliseconds: 100), () {
                      setState(() => showLocationButton = true);
                    });

                  }
                },
              ),
              userLocationPoint != null
                ? Align(
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  opacity: showLocationButton ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: 230.0,
                      child: ElevatedButton(
                        style: getTextButtonStyle(
                          TextButtonStyle(size: 1, theme: 'secondary')
                        ),
                        onPressed: () {
                          controller.moveCamera(
                            CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: userLocationPoint!,
                                    zoom: 14
                                )
                            ),
                            animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.5),
                          );
                        },
                        child: const Text('Показать рядом со мной'),
                      ),
                    ),
                  ),
                )
              )
              : const SizedBox.shrink(),
            ],
          );
        }
      }
    );
  }

  void onTapBranch(Branch branch) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.center,
                    direction: Axis.horizontal,
                    children: [
                      const SizedBox(
                          width: 57,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.pin_drop_outlined,
                              color: Colors.grey,
                            ),
                          )
                      ),
                      Expanded(
                          child: Text(
                              '${branch.name}, ${branch.address}',
                              style: const TextStyle(fontSize: 15)
                          )
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ExpansionTile(
                  leading: const Icon(
                    Icons.access_time_outlined,
                    color: Colors.grey,
                  ),
                  title: Text(
                    getWorkHoursString(branch),
                    style: const TextStyle(fontSize: 15),
                  ),
                  subtitle: (branch.timeBreak != '')
                      ? Text('Перерыв: ${branch.timeBreak.replaceAll('-', '–')}')
                      : null,
                  children: getWorkingHoursDays(branch, 10),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: GestureDetector(
                    onTap: () {
                      // makePhoneCall(branch.phone);
                      makePhoneCall(globalPhoneNumber);
                    },
                    child: Flex(
                      mainAxisAlignment: MainAxisAlignment.center,
                      direction: Axis.horizontal,
                      children: [
                        const SizedBox(
                          width: 57,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.call_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Text(
                              // branch.phone_branch,
                                globalPhoneNumber,
                                style: const TextStyle(fontSize: 15)
                            )
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Ink(
                            padding: EdgeInsets.zero,
                            width: 40,
                            height: 40,
                            decoration: const ShapeDecoration(
                              color: primaryLightColor,
                              shape: CircleBorder(),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call_outlined),
                              color: primaryColor,
                              onPressed: () {
                                // makePhoneCall(branch.phone);
                                makePhoneCall(globalPhoneNumber);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => context.go(
                                '/contacts/branch',
                                extra: branch
                            ),
                            style: getTextButtonStyle(
                                TextButtonStyle(size: 1)
                            ),
                            child: const Text('Подробнее'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: getTextButtonStyle(
                                TextButtonStyle(
                                  theme: 'primaryLight',
                                  size: 1,
                                )
                            ),
                            child: const Text('Закрыть'),
                          ),
                        ),
                      ],
                    )
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}
