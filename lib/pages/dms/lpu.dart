import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'lpu_list.dart';
import 'lpu_map.dart';


class DmsLpuPage extends StatefulWidget {
  final String policyId;
  const DmsLpuPage({super.key, required this.policyId});

  @override
  State<DmsLpuPage> createState() => _DmsLpuPageState();
}

class _DmsLpuPageState extends State<DmsLpuPage> {

  YandexMapController? controller;
  Point? clickedPoint;

  // достанем контроллер карты из виджета карты
  setMapController(YandexMapController mapController) {
    setState(() {
      controller = mapController;
    });
  }

  // переход к поинту на карте
  goToMapPoint(Point point) {
    setState(() {
      clickedPoint = point;
      controller?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 16),
        ),
        // todo: падает при анимации
        // animation: const MapAnimation(type: MapAnimationType.smooth, duration: 2.0)
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ЛПУ'),
          bottom: TabBar(
            indicatorWeight: 5,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 10),
                  child: Text('Список')
              ),
              Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 10),
                  child: Text('Карта')
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DmsLpuList(
              policyId: widget.policyId,
              goToMapPoint: goToMapPoint,
            ),
            DmsLpuMap(
              policyId: widget.policyId,
              setMapController: setMapController,
              clickedPoint: clickedPoint,
            ),
          ],
        ),
      ),
    );
  }
}
