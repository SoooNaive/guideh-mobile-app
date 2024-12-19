import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';

import 'functions.dart';
import 'models.dart';


class CheckupHouseStart extends StatefulWidget {
  final Map<String, String>? queryParameters;
  const CheckupHouseStart({super.key, required this.queryParameters});

  @override
  State<CheckupHouseStart> createState() => _CheckupHouseStartState();
}

class _CheckupHouseStartState extends State<CheckupHouseStart> {

  bool isLoading = false;
  bool isLoadingUserLocation = false;

  late final String? parentId;
  String? insurerName;
  String? objectAddress;
  String? checkStatusId;

  late List<CheckupHouseCaseObject> httpCaseObjects;
  late Future<void> _initDataLoad;
  Future<void> _initData() async {
    httpCaseObjects = parentId == null ? [] : await _loadCase(parentId!);
  }

  @override
  void initState() {
    super.initState();
    parentId = widget.queryParameters?['parent_id'];
    _initDataLoad = _initData();
  }

  @override
  Widget build(BuildContext context) {
    String? errorText;
    if (parentId == null || parentId == '') {
      errorText = 'Ошибка: не передан ID родительского документа.';
    }
    else if (checkStatusId == '948-02') {
      errorText = 'Фотографии осмотра находятся на проверке. Ожидайте СМС с результатами.';
    }
    else if (checkStatusId == '948-04') {
      errorText = 'Фотографии осмотра проверены и приняты.';
    }
    else if (checkStatusId == '948-05') {
      errorText = 'Фотографии осмотра не приняты.';
    }
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => exitCheckupDialog(context),
          icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
        ),
        title: const Text('Осмотр загородного дома'),
      ),

      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorText != null
          ? _errorWidget(errorText)
          : FutureBuilder(
              future: _initDataLoad,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                  case ConnectionState.active: {
                    return const Center(child: CircularProgressIndicator());
                  }
                  case ConnectionState.done: {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          if (checkStatusId == '948-03') const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: CommentAlert(
                              'Приняты не все фотографии. Пожалуйста, добавьте необходимые фото, следуя комментариям.',
                              true
                            ),
                          ),

                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Страхователь',
                            ),
                            style: const TextStyle(color: Colors.black),
                            enabled: false,
                            initialValue: insurerName ?? '—',
                          ),

                          if ((objectAddress ?? '') != '') TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Адрес объекта',
                            ),
                            style: const TextStyle(color: Colors.black),
                            enabled: false,
                            initialValue: objectAddress,
                            minLines: 1,
                            maxLines: 4,
                          ),

                          const SizedBox(height: 40),

                          TextButton(
                            style: getTextButtonStyle(),
                            onPressed: () {
                              if (isLoadingUserLocation) return;
                              _startCheckup();
                            },
                            child: isLoadingUserLocation
                              ? const SizedBox(
                                  height: 16.0,
                                  width: 16.0,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : Text('${checkStatusId == '948-03' ? 'Продолжить' : 'Начать'} осмотр'),
                          ),
                          const SizedBox(height: 10),
                          _goAppButton(),
                        ],
                      ),
                    );
                  }
                }
              },
            )
    );
  }


  Widget _goAppButton() => TextButton(
    style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
    onPressed: () {
      if (isLoadingUserLocation) return;
      setState(() => isLoading = true);
      context.go('/polis_list');
    },
    child: const Text('Вернуться в приложение'),
  );


  Widget _errorWidget(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 30),
        _goAppButton(),
      ],
    )
  );


  void _startCheckup() async {

    setState(() => isLoadingUserLocation = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Сервис определения местоположения отключён. Включите модуль GPS.')
          ),
        );
      }

      setState(() => isLoadingUserLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 5),
                content: Text('Доступ к определению местоположению запрещён. Необходимо предоставить разрешение.')
            ),
          );
        }

        setState(() => isLoadingUserLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Доступ к определению местоположения запрещён. Предоставьте разрешение в настройках приложения.')
          ),
        );
      }

      setState(() => isLoadingUserLocation = false);
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {

      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 60),
        )
      );

      if (mounted) {
        context.goNamed(
          'checkup_house',
          queryParameters: { 'parentId': parentId },
          extra: httpCaseObjects
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Не удалось определить местоположение. Попробуйте ещё раз.')
          ),
        );
      }
      setState(() => isLoadingUserLocation = false);
      return;
    }

  }

  Future<List<CheckupHouseCaseObject>> _loadCase(String parentId) async {
    final response = await Http.mobApp(
        ApiParams('Checkuphouse', 'Case', { 'ParentId': parentId })
        // ApiParams('Checkuphouse', 'Case', { 'ParentId': '54a894dd-48b5-11ee-80ef-00155d65b0a0' })
    );

    // todo: сделать проверку, что parentId вообще есть такой parent

    setState(() {
      insurerName = response['Case']?['Polis']?['Insurer'];
      objectAddress = response['Case']?['Polis']?['ObjectAddress'];
      checkStatusId = response['Case']['StatusId'];
    });

    // чистый кейс
    if (!response.containsKey('Data') || response['Data'].isEmpty) {
      return defaultCaseObjects;
    }

    // кейс не первой свежести
    final caseObjectsMap = response['Data'];
    List<CheckupHouseCaseObject> caseObjects = [];
    for (var object in caseObjectsMap) {
      caseObjects.add(CheckupHouseCaseObject.fromJson(object));
    }
    return caseObjects;
  }

}
