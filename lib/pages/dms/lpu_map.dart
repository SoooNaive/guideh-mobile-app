import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/services/location.dart';
import 'package:guideh/theme/theme.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'models/lpu.dart';


class DmsLpuMap extends StatefulWidget {
  final String policyId;
  final Function(YandexMapController controller)? setMapController;
  final Point? clickedPoint;
  const DmsLpuMap({
    super.key,
    required this.policyId,
    this.clickedPoint,
    this.setMapController,
  });

  @override
  DmsLpuMapState createState() => DmsLpuMapState();
}

class DmsLpuMapState extends State<DmsLpuMap> with AutomaticKeepAliveClientMixin<DmsLpuMap>, TickerProviderStateMixin {

  @override
  bool get wantKeepAlive => true;

  String userCityId = '1';

  GlobalKey mapKey = GlobalKey();
  late List<MapObject> mapObjects = [];
  late YandexMapController controller;

  late List<String> regions;
  late List<DmsLpu> lpusToShow;

  late PageController _pageViewController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    final dpi = MediaQuery.of(context).devicePixelRatio;

    return FutureBuilder(
        future: getDmsLpuMap(context, widget.policyId),
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

            final List<String> regions = snapshot.data.map((item) {
              return item['Region'] as String;
            }).toList().cast<String>();

            return PageView(
              controller: _pageViewController,
              physics: NeverScrollableScrollPhysics(),
              children: [

                // регионы
                ListView.separated(
                  separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
                  itemCount: regions.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(snapshot.data[index]['Region']),
                      onTap: () {
                        lpusToShow = snapshot.data[index]['LPU'];
                        _tabController.index = 1;
                        _pageViewController.jumpToPage(1);
                      },
                      trailing: Icon(Icons.chevron_right),
                      shape: index == (regions.length -1)
                        ? Border(bottom: BorderSide(color: Colors.black12))
                        : null,
                    );
                  },
                ),

                // карта
                Stack(
                  alignment: Alignment.center,
                  children: [
                    YandexMap(
                      key: mapKey,
                      mapObjects: mapObjects,
                      onMapCreated: (YandexMapController yandexMapController) async {
                        controller = yandexMapController;

                        // передаём контроллер карты родителю
                        widget.setMapController!(yandexMapController);

                        // зум к ЛПУ, если был клик в списке
                        if (widget.clickedPoint != null) {
                          controller.moveCamera(
                            CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: widget.clickedPoint!,
                                    zoom: 16
                                )
                            ),
                          );
                        }
                        // зум по всем точкам
                        else {
                          List<List<String>> coordinatesArray = [];
                          for (var i = 0; i < lpusToShow.length; i++) {
                            DmsLpu lpu = lpusToShow[i];
                            if ((lpu.latitude ?? '') != '' && (lpu.longitude ?? '') != '') {
                              coordinatesArray.add([lpu.latitude!, lpu.longitude!]);
                            }
                          }

                          final bounds = getBounds(coordinatesArray);

                          controller.moveCamera(
                            CameraUpdate.newGeometry(
                              Geometry.fromBoundingBox(BoundingBox(
                                northEast: Point(latitude: bounds[0][0], longitude: bounds[0][1]),
                                southWest: Point(latitude: bounds[1][0], longitude: bounds[1][1]),
                              ))
                            )
                          );
                        }

                        // * цикл

                        List<PlacemarkMapObject> allMapObjects = [];
                        for (var i = 0; i < lpusToShow.length; i++) {
                          DmsLpu lpu = lpusToShow[i];
                          // todo: add checks
                          if ((lpu.latitude ?? '') != '' && (lpu.longitude ?? '') != '') {
                            allMapObjects.add(
                                PlacemarkMapObject(
                                  mapId: MapObjectId(lpu.index.toString()),
                                  point: Point(
                                      latitude: double.parse(lpu.latitude!),
                                      longitude: double.parse(lpu.longitude!)
                                  ),
                                  icon: PlacemarkIcon.single(
                                      PlacemarkIconStyle(
                                          image: BitmapDescriptor.fromAssetImage('assets/images/placemark-lpu.png'),
                                          zIndex: 1,
                                          scale: dpi * 0.28,
                                          rotationType: RotationType.noRotation
                                      )
                                  ),
                                  opacity: 1,
                                  onTap: (PlacemarkMapObject self, Point point) => onTapLpu(lpu),
                                  consumeTapEvents: true,
                                )
                            );
                          }
                        }
                        setState(() => mapObjects.addAll(allMapObjects));
                      },
                    ),

                    // [назад]
                    Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: ElevatedButton.icon(
                            icon: SizedBox(width: 12, child: Icon(Icons.chevron_left)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              padding: EdgeInsets.only(left: 8, right: 16),
                            ),
                            onPressed: () {
                              lpusToShow = [];
                              _tabController.index = 0;
                              _pageViewController.jumpToPage(0);
                            },
                            label: const Text('Регионы'),
                          ),
                        )
                    ),

                  ],
                ),

              ],
            );

          }
        }
    );
  }

  void onTapLpu(DmsLpu lpu) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                ListTile(
                  minVerticalPadding: 10,
                  leading: const Icon(
                    Icons.domain_add,
                    color: Colors.grey,
                  ),
                  title: Text(
                    lpu.name,
                  ),
                ),

                const Divider(height: 0),

                ListTile(
                  minVerticalPadding: 10,
                  leading: const Icon(
                    Icons.pin_drop_outlined,
                    color: Colors.grey,
                  ),
                  title: Text(
                    lpu.address,
                    style: const TextStyle(color: Colors.black45),
                  ),
                ),

                const Divider(height: 0),

                if (lpu.phones != null && lpu.phones!.isNotEmpty) Column(
                  children: [
                    ...lpu.phones!.map((String phone) => Column(
                      children: [
                        ListTile(
                          onTap: () => makePhoneCall(phone),
                          minVerticalPadding: 10,
                          leading: const Icon(
                            Icons.call_outlined,
                            color: Colors.grey,
                          ),
                          title: Text(
                            phone,
                            style: const TextStyle(color: Colors.black45),
                          ),
                          trailing: Ink(
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
                              disabledColor: primaryColor,
                              onPressed: null,
                            ),
                          ),
                        ),
                        const Divider(height: 0),
                      ],
                    )),
                  ],
                ),

                Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => context.goNamed(
                              'dms_lpu_add_req',
                              queryParameters: {
                                'policy_id': widget.policyId,
                              },
                              extra: DmsLpu(
                                id: lpu.id,
                                name: lpu.name,
                                address: lpu.address,
                              ),
                            ),
                            style: getTextButtonStyle(
                                TextButtonStyle(size: 1)
                            ),
                            child: const Text('Записаться к врачу'),
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


  Future<List<Map<String, dynamic>>> getDmsLpuMap(BuildContext context, polisId) async {
    final response = await Http.mobApp(
        ApiParams( 'MobApp', 'MP_ExecuteDMSMethod', {
          'token': await Auth.token,
          'Method': 'MP_polis_lpu2',
          'PolisId': polisId,
        })
    );

    if (response?['Error'] == 0 && response['Data']['Error'] == '3') {
      List<Map<String, dynamic>> data = [];
      var lpuIndex = 0;

      for (var region in response['Data']['Data']) {
        try {
          data.add({
            'Region': region['Region'],
            'LPU': (region['LPU'] as List).map((lpu) {
              return DmsLpu(
                index: lpuIndex++,
                id: lpu['Id'],
                name: lpu['Name'],
                address: lpu['Address'],
                latitude: lpu['Latitude'],
                longitude: lpu['Longitude'],
                phones: List<String>.from(lpu['Phones']),
              );
            }).toList()
          });
        } catch (e) {
          print(e);
        }

      }
      return data;
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['Message'] ?? 'Ошибка'),
          ),
        );
      }
      return [];
    }
  }

}
