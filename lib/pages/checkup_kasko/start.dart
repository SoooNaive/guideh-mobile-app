import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'photo_model.dart';


class CheckupKaskoStart extends StatefulWidget {
  final Map<String, String> queryParameters;
  const CheckupKaskoStart({super.key, required this.queryParameters});

  @override
  State<CheckupKaskoStart> createState() => _CheckupKaskoStartState();
}

class _CheckupKaskoStartState extends State<CheckupKaskoStart> {

  bool isLoading = false;
  bool isLoadingUserLocation = false;

  late final String? parentId;
  late final String? docId;
  late final String? omegaId;
  late final String? sputnikId;

  String? checkupStatusId;

  late Map<String, dynamic>? polisData;
  late Future<void> _initDataLoad;
  Future<void> _initData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove('draftKaskoCheckupId');
    polisData = await _loadPolis();
    setState(() => checkupStatusId = polisData?['CheckupStatusId']);
  }

  @override
  void initState() {
    super.initState();
    docId = widget.queryParameters['DocId'];
    omegaId = widget.queryParameters['OmegaId'];
    sputnikId = widget.queryParameters['SputnikId'];
    parentId = docId ?? omegaId ?? sputnikId;
    _initDataLoad = _initData();
  }

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

      body: isLoading
        ? const Center(child: CircularProgressIndicator())
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
                  if (polisData == null) {
                    return _errorWidget('Передан некорректный ID полиса.');
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Номер полиса',
                          ),
                          style: const TextStyle(color: Colors.black),
                          enabled: false,
                          initialValue: polisData?['DocNumber'] ?? '—',
                        ),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Страхователь',
                          ),
                          style: const TextStyle(color: Colors.black),
                          enabled: false,
                          initialValue: polisData?['Insurer'] ?? '—',
                        ),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Транспортное средство',
                          ),
                          style: const TextStyle(color: Colors.black),
                          enabled: false,
                          initialValue: polisData?['Auto'] ?? '—',
                        ),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Сроки страхования',
                          ),
                          style: const TextStyle(color: Colors.black),
                          enabled: false,
                          initialValue: '${polisData?['DateActionBeg'] ?? '_'} — ${polisData?['DateActionEnd'] ?? '_'}',
                        ),

                        if (polisData!['Checkup'] == false && !['31','32','33'].contains(checkupStatusId))
                          const CheckupKaskoStartAlert(text: 'Осмотр не требуется.')

                        else if (checkupStatusId == '31')
                          const CheckupKaskoStartAlert(text: 'Фотографии осмотра находятся на проверке. Ожидайте СМС с результатами.')

                        else if (checkupStatusId == '32')
                          const CheckupKaskoStartAlert(text: 'Необходимо загрузить новые фотографии.')

                        else if (checkupStatusId == '33')
                          const CheckupKaskoStartAlert(text: 'Фотографии осмотра проверены и приняты.',
                            bgColor: Color(0xffd0f3ad),
                            textColor: Color(0xff355710),
                          )

                        else const SizedBox(height: 40),

                        if (polisData!['Checkup'] == true && !['31','33'].contains(checkupStatusId))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextButton(
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
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    checkupStatusId == '32'
                                      ? const Text('Загрузить фотографии')
                                      : const Text('Начать осмотр'),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.east, size: 20)
                                  ],
                                )
                            ),
                          ),

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
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.west, size: 20),
        SizedBox(width: 8),
        Flexible(child: Text('Вернуться в приложение')),
      ],
    ),
  );


  Widget _errorWidget(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        const SizedBox(height: 20),
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

    if (!context.mounted) {
      setState(() => isLoadingUserLocation = false);
      return;
    }

    // начать осмотр → определяем на какой шаг перейти

    // если статус "направлен на доработку"
    if (checkupStatusId == '32') {

      // грузим кейс чекапа
      final Map<String, dynamic>? checkupData = await Http.mobApp(
          ApiParams('Checkup', 'DocCase', { 'DocId': polisData!['CheckupDocId'] })
      );
      if (checkupData == null || checkupData['Case']?['Files'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 5),
                content: Text('Ошибка загрузки данных осмотра.')
            ),
          );
          setState(() => isLoadingUserLocation = false);
        }
        return;
      }

      final photosData = checkupData['Case']?['Files'] as List<dynamic>?;
      final photos = photosData != null
          ? photosData.map((photoData) => CheckupKaskoPhoto.fromMap(photoData)).toList()
          : <CheckupKaskoPhoto>[];
      final deniedPhotos = photos.where((photo) => photo.check == '0').toList();

      if (deniedPhotos.isEmpty) {
        // если нет неодобренных фоток, но "отправлен на доработку" - вообще не должно быть
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 5),
                content: Text('Нет неодобренных фотографий. Ожидайте уведомление или обратитесь в поддержку.')
            ),
          );
          setState(() => isLoadingUserLocation = false);
        }
        return;
      }

      if (hasDeniedPhotos(photos, 'car_photos')) {
        _goToStep('car_photos', checkupData);
      }
      else if (hasDeniedPhotos(photos, 'extra_photos')) {
        _goToStep('extra_photos', checkupData);
      }
      else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 5),
                content: Text('Фотографии на проверке. Ожидайте уведомление.')
            ),
          );
          setState(() => isLoadingUserLocation = false);
        }
      }
    }
    else {
      _goToStep('car_photos');
    }
  }

  void _goToStep(String stepName, [Map<String, dynamic>? checkupData]) async {
    if (checkupData?['Case']?['DocId'] != null) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString('draftKaskoCheckupId', checkupData!['Case']['DocId']);
    }
    final String parentIdType =
      docId != null ? 'DocId' :
      omegaId != null ? 'OmegaId' :
      sputnikId != null ? 'SputnikId' : '';
    if (!mounted) return;
    context.goNamed(
      'checkup_kasko',
      queryParameters: {
        'parentId': parentId,
        'parentIdType': parentIdType,
        'stepName': stepName,
      },
      extra: checkupData,
    );
  }

  // кейс полиса PolisData
  Future<Map<String, dynamic>?> _loadPolis() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var params = { 'Phone': preferences.getString('phone') ?? '' };
    if (docId != null) {
      params['DocId'] = docId!;
    } else if (omegaId != null) {
      params['OmegaId'] = omegaId!;
    } else if (sputnikId != null) {
      params['SputnikId'] = sputnikId!;
    }
    final response = await Http.mobApp(
        ApiParams('Checkup', 'PolisData', params)
    );

    if (!response.containsKey('DocNumber') || response['DocNumber'] == '') {
      return null;
    }
    return response;
  }

}

class CheckupKaskoStartAlert extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color? bgColor;
  const CheckupKaskoStartAlert({
    super.key,
    required this.text,
    this.textColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor ?? const Color(0xffefeacc),
          borderRadius: const BorderRadius.all(Radius.circular(5))
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: textColor ?? const Color(0xff735727),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text, style: TextStyle(color: textColor ?? const Color(0xff735727))
              )
            ),
          ],
        ),
      ),
    );
  }
}
