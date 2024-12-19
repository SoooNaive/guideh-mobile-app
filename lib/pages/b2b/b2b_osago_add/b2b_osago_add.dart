import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/b2b_osago_add_car.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/b2b_osago_add_driver.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/b2b_osago_add_person.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/b2b_osago_photo_model.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/modal_bottom_sheet.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gai_api_request.dart';

class B2BOsagoAdd extends StatefulWidget {
  final Map<String, String>? queryParameters;
  const B2BOsagoAdd({super.key, this.queryParameters});

  // распознавание
  static Future<bool> getVision(String model, String imagePath, Future Function(List<dynamic>) callback) async {
    final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    final request = http.Request('POST',
        Uri.parse('https://client.guideh.com/api/MobApp_DocRecognize.php')
    );
    print('session: ${sharedPrefs.getString('session')}');
    request.body = json.encode({
      'base64': base64Encode(File(imagePath).readAsBytesSync()),
      'session': sharedPrefs.getString('session') ?? '',
      'model': model,
    });
    request.headers.addAll({'Content-Type': 'application/json'});
    http.StreamedResponse response = await request.send();
    final responseString = await response.stream.bytesToString();
    Map<String, dynamic>? decodedJSON;
    try {
      decodedJSON = json.decode(responseString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      print('! Ответ не JSON: ${e.message}');
      return false;
    }
    sharedPrefs.setString('session', decodedJSON['session'] ?? '');
    if (decodedJSON['pages'] == null) {
      print('Ошибка распознования: нет тега pages');
      return false;
    }
    else {
      print(json.encode(decodedJSON['pages'][0]['entities']));
      await callback(decodedJSON['pages']);
      return true;
    }
  }

  @override
  State<B2BOsagoAdd> createState() => _B2BOsagoAddState();
}

class _B2BOsagoAddState extends State<B2BOsagoAdd> {

  final formKey = GlobalKey<FormState>();
  final DateTime now = DateTime.now();
  late DateTime tomorrow;
  final TextEditingController _dateActionBegController = TextEditingController();

  Map<String, dynamic>? policyHolderData;
  Map<String, dynamic>? ownerData;
  Map<String, dynamic>? carData;
  List<Map<String, dynamic>>? driversData;

  late List<B2BOsagoAddPhoto> photos;
  late List<List<B2BOsagoAddPhoto>?> photosDrivers;

  bool ownerIsInsurer = false;
  int? policyHolderDriverIndex;
  int? ownerDriverIndex;
  bool isCalculating = false;

  String? _calculationId;

  @override
  void initState() {
    super.initState();
    photos = [];
    photosDrivers = [];
    // дата начала – завтра
    tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    _dateActionBegController.text = DateFormat('dd.MM.yyyy').format(tomorrow);
  }


  @override
  Widget build(BuildContext context) {
    final bool hasDrivers = driversData != null && driversData!.isNotEmpty;
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: const Text('Полис ОСАГО'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: _dateActionBegController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.today_rounded),
                        labelText: 'Дата начала действия',
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [DateTextFormatter()],
                      onTap: () async {
                        final DateTime? selected = await showDatePicker(
                          locale: const Locale('ru', 'ru_Ru'),
                          context: context,
                          fieldHintText: 'DATE/MONTH/YEAR',
                          initialDate: tomorrow,
                          firstDate: tomorrow,
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (selected != null) {
                          setState(() {
                            _dateActionBegController.text = DateFormat('dd.MM.yyyy').format(selected);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Укажите дату начала действия полиса';
                        }
                        if (value.length < 10) {
                          return 'Неверный формат даты';
                        }
                        final DateTime date = DateFormat('dd.MM.yyyy').parse(value);
                        if (date.isBefore(tomorrow)) {
                          return 'Дата не должна быть ранее чем завтра';
                        }
                        if (date.isAfter(DateTime.now().add(const Duration(days: 30)))) {
                          return 'Дата не должна быть позднее чем +30 дней';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton.icon(
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: policyHolderData == null ? 1 : 0.65,
                                child: const Text('Страхователь')
                              ),
                              if (policyHolderData != null) Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  policyHolderData!['fullName'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        policyHolderData == null
                          ? const Icon(Icons.add)
                          : const Icon(Icons.edit, size: 22),
                      ],
                    ),
                    onPressed: () async {
                      Map<String, dynamic>? stepResponse = await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => B2BOsagoAddPerson(
                          data: policyHolderData,
                          personType: 'policyHolder',
                          photos: photos.where((photo) => photo.type == 'policyHolder')
                            .map((photo) => photo.path).toList(),
                          updatePhotos: _updatePhotos,
                        )
                      ));
                      if (stepResponse == null) return;
                      setState(() => policyHolderData = stepResponse);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: policyHolderData == null ? secondaryLightColor : secondaryColor,
                      foregroundColor: policyHolderData == null ? primaryColor : Colors.white,
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    icon: const Icon(Icons.account_circle_outlined),
                    label: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: ownerData == null ? 1 : 0.65,
                                child: Text('Собственник${ownerIsInsurer ? ' = Страхователь' : ''}')
                              ),
                              if (ownerData != null) Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  ownerData!['fullName'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ownerData == null
                          ? const Icon(Icons.add)
                          : const Icon(Icons.edit, size: 22),
                      ],
                    ),
                    onPressed: () async {
                      Map<String, dynamic>? stepResponse = await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => B2BOsagoAddPerson(
                          data: ownerData,
                          personType: 'owner',
                          ownerIsInsurer: ownerIsInsurer,
                          getOwnerIsInsurer: () => policyHolderData,
                          photos: photos.where((photo) => photo.type == 'owner')
                            .map((photo) => photo.path).toList(),
                          updatePhotos: _updatePhotos,
                        )
                      ));
                      if (stepResponse == null) return;
                      setState(() {
                        ownerData = stepResponse;
                        ownerIsInsurer = const DeepCollectionEquality().equals(ownerData, policyHolderData);
                      });
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: ownerData == null ? secondaryLightColor : secondaryColor,
                        foregroundColor: ownerData == null ? primaryColor : Colors.white,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    icon: const Icon(Icons.directions_car_filled_outlined),
                    label: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: carData == null ? 1 : 0.65,
                                child: const Text('Транспортное средство')
                              ),
                              if (carData != null) Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${carData!['make']} ${carData!['model']} • ${carData!['licensePlate']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        carData == null
                          ? const Icon(Icons.add)
                          : const Icon(Icons.edit, size: 22),
                      ],
                    ),
                    onPressed: () async {
                      Map<String, dynamic>? stepResponse = await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => B2BOsagoAddCar(
                          data: carData,
                          photos: photos.where((photo) => photo.type == 'vehicle')
                            .map((photo) => photo.path).toList(),
                          updatePhotos: _updatePhotos,
                        )
                      ));
                      if (stepResponse == null) return;
                      setState(() => carData = stepResponse);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: carData == null ? secondaryLightColor : secondaryColor,
                      foregroundColor: carData == null ? primaryColor : Colors.white,
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (hasDrivers) ...driversData!.mapIndexed((driverIndex, driver) {

                    final bool policyHolderIsDriver =
                      policyHolderDriverIndex != null && policyHolderDriverIndex == driverIndex;
                    final bool ownerIsDriver =
                      !policyHolderIsDriver && ownerDriverIndex != null && ownerDriverIndex == driverIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton.icon(
                        icon: const Icon(Icons.person_outline),
                        label: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Opacity(
                                    opacity: 0.65,
                                    child: Text(
                                      'Водитель #${driverIndex + 1}${policyHolderIsDriver
                                        ? ' = Страхователь'
                                        : (ownerIsDriver
                                          ? ' = Собственник'
                                          : '')}'
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      driver['name'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit, size: 22),
                          ],
                        ),
                        onPressed: () async {
                          Map<String, dynamic>? stepResponse = await Navigator.push(
                            context, MaterialPageRoute(builder: (context) => B2BOsagoAddDriver(
                              data: driver,
                              policyHolderData: policyHolderData,
                              ownerData: ownerData,
                              ownerIsInsurer: ownerIsInsurer,
                              policyHolderIsDriver: policyHolderDriverIndex != null,
                              ownerIsDriver: ownerDriverIndex != null,
                              driverIndex: driverIndex,
                              photosDriver: photosDrivers[driverIndex]?.map((photo) => photo.path).toList(),
                              updatePhotosDrivers: _updatePhotosDrivers,
                              deleteDriver: (int driverIndex) {
                                // удаляем водителя и фотки
                                driversData!.removeAt(driverIndex);
                                photosDrivers.removeAt(driverIndex);
                                // фиксим индексы
                                if (policyHolderDriverIndex != null) {
                                  if (policyHolderDriverIndex == driverIndex) {
                                    policyHolderDriverIndex = null;
                                  } else if (policyHolderDriverIndex! > driverIndex) {
                                    policyHolderDriverIndex = policyHolderDriverIndex! - 1;
                                  }
                                }
                                if (ownerDriverIndex != null) {
                                  if (ownerDriverIndex == driverIndex) {
                                    ownerDriverIndex = null;
                                  } else if (ownerDriverIndex! > driverIndex) {
                                    ownerDriverIndex = ownerDriverIndex! - 1;
                                  }
                                }
                                setState(() {});
                              },
                            )
                          ));
                          if (stepResponse == null) return;
                          setState(() {
                            driversData![driverIndex] = stepResponse;
                          });
                        },
                        style: TextButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                        ),
                      ),
                    );
                  }),

                  TextButton.icon(
                    icon: const Icon(Icons.groups_outlined),
                    label: Row(
                      children: [
                        Expanded(
                          child: Text(hasDrivers ? 'Добавить водителя' : 'Водители'),
                        ),
                        const Icon(Icons.add),
                      ],
                    ),
                    onPressed: () async {
                      Map<String, dynamic>? stepResponse = await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => B2BOsagoAddDriver(
                          data: null,
                          policyHolderData: policyHolderData,
                          ownerData: ownerData,
                          ownerIsInsurer: ownerIsInsurer,
                          policyHolderIsDriver: policyHolderDriverIndex != null,
                          ownerIsDriver: ownerDriverIndex != null,
                          driverIndex: hasDrivers ? driversData!.length : 0,
                          updatePhotosDrivers: _updatePhotosDrivers,
                        )
                      ));
                      if (stepResponse == null) return;
                      setState(() {
                        driversData ??= [];
                        driversData!.add(stepResponse);
                        if (stepResponse['name'] == policyHolderData?['fullName']) {
                          policyHolderDriverIndex = driversData!.length - 1;
                        }
                        else if (stepResponse['name'] == ownerData?['fullName']) {
                          ownerDriverIndex = driversData!.length - 1;
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: secondaryLightColor,
                      foregroundColor: primaryColor,
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                    ),
                  ),

                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: TextButton(
                    style: getTextButtonStyle(),
                    onPressed: isCalculating ? null : calculateOsago,
                    onLongPress: () {
                      calculateOsago(true);
                    },
                    child: SizedBox(
                      height: 22,
                      child: isCalculating
                        ? Container(
                          padding: const EdgeInsets.all(2),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Расчёт... ', style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.white
                              )),
                            ],
                          ),
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Рассчитать ОСАГО'),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_right_alt),
                          ],
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

  // собираем данные в формат для GAI API
  Map<String, dynamic> getDataForGaiApi() {
    final Map<String, dynamic> json = {
      "insuranceContract": {
        "dateActionBeg": _dateActionBegController.text,
        "periodMonths": 12
      },
      "vehicle": carData,
      "policyHolder": policyHolderData,
      "owner": ownerData,
      "drivers": driversData ?? [],
    };
    return json;
  }

  // валидация заполненности формы
  List<String> validateForm() {
    List <String> errors = [];
    if (policyHolderData == null) errors.add('Страхователь');
    if (ownerData == null && !(ownerIsInsurer && policyHolderData != null)) errors.add('Собственник');
    if (carData == null) errors.add('Транспортное средство');
    return errors;
  }

  // [рассчитать ОСАГО]
  void calculateOsago([bool? isTest]) async {
    final test = isTest ?? false;

    // проверка даты начала
    if (!formKey.currentState!.validate()) {
      return;
    }

    // проверка заполненности остального
    final errors = validateForm();
    if (!test && errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Не заполнены обязательные данные:'),
              const SizedBox(height: 6),
              Text(errors.join(', ')),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => isCalculating = true);
    final calcResponse = await gaiApiRequest('/calculation/', test ? testDataGood : getDataForGaiApi(), context);
    print(calcResponse);
    final String? calculationId = calcResponse?['calculationId'];
    setState(() => _calculationId = calculationId);
    if (calculationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            showCloseIcon: true,
            closeIconColor: Colors.white,
            content: Text('Ошибка получения проекта расчёта')
          ),
        );
      }
      setState(() => isCalculating = false);
      return;
    }

    print('go get calculate!');

    // get запросы в calculate
    int counter = 8;
    while (counter > 0) {
      await Future.delayed(const Duration(seconds: 4));
      Map<String, dynamic>? calcGetResponse;
      if (mounted) {
        calcGetResponse =
          await gaiApiRequest('/calculation/?calculationId=$calculationId', null, context);
      } else {
        return;
      }
      final status = calcGetResponse?['status'];
      if (status == 3) {
        final double? ratesOsago = calcGetResponse?['ratesOSAGO']['premium'];
        if (ratesOsago != null) {
          showCalcResult(calcGetResponse!);
          await Future.delayed(const Duration(seconds: 1));
        }
        else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка расчёта'), showCloseIcon: true),
          );
        }
        counter = 1;
      }
      else if (calcGetResponse?['error'] is List && calcGetResponse?['error'].isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка. ${calcGetResponse!['error']![0]}'),
              showCloseIcon: true,
            ),
          );
        }
        counter = 1;
      }
      counter--;
    }
    setState(() => isCalculating = false);
  }

  // показываем расчёт
  void showCalcResult(Map<String, dynamic> calcResult) {
    if (_calculationId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        if (_calculationId == null) {
          return const SizedBox.shrink();
        }
        return B2BOsagoModalBottomSheet(
          calculationId: _calculationId!,
          calcResult: calcResult,
          uploadPhotos: _uploadPhotos,
        );
      },
    ).whenComplete(() {
      setState(() {
        isCalculating = false;
        _calculationId = null;
      });
    });
  }

  // обновляем фотки
  void _updatePhotos(List<String> newPhotos, String photosType) {
    final int hasSamePhotoIndex = photos.indexWhere((photo) => photo.type == photosType);
    if (hasSamePhotoIndex > -1) {
      photos.removeAt(hasSamePhotoIndex);
    }
    for (var photo in newPhotos) {
      photos.add(B2BOsagoAddPhoto(path: photo, type: photosType));
    }
  }

  // обновляем фотки водителей
  void _updatePhotosDrivers(List<String> newPhotos, int driverIndex) {
    final List<B2BOsagoAddPhoto>? value = newPhotos.isEmpty ? null : newPhotos.map((photo) {
      return B2BOsagoAddPhoto(path: photo, type: 'driver_$driverIndex');
    }).toList();
    if (photosDrivers.length <= driverIndex) {
      photosDrivers.add(value);
    } else {
      photosDrivers[driverIndex] = value;
    }
  }

  // грузим фотки на бэк перед оплатой полиса
  Future<bool> _uploadPhotos(String contractId) async {
    print('грузим фотки');
    List<List<B2BOsagoAddPhoto>> filteredPhotosDrivers =
      photosDrivers.whereType<List<B2BOsagoAddPhoto>>().toList();
    // собираем фотки водителей в общий массив
    List<B2BOsagoAddPhoto> photosDriversList = [];
    for (var list in filteredPhotosDrivers) {
      for (var photo in list) {
        photosDriversList.add(photo);
      }
    }
    print([...photos, ...photosDriversList].length);
    int fileCount = 1;
    await Future.forEach([...photos, ...photosDriversList], (B2BOsagoAddPhoto photo) async {
      final photoJsonObject = photo.toJson();
      print(photoJsonObject);
      await gaiApiRequest('/uploadFile/', {
        'contractId': contractId,
        'file': {
          'name': '${fileCount}_${photoJsonObject["name"]}',
          'data': photoJsonObject['data'],
        }
      }, context);
      fileCount++;
      print('есть фотка');
    });
    print('загрузили фотки');
    return true;
  }

}


Map<String, dynamic> testData = {
  "insuranceContract": {
    "dateActionBeg": "30.02.2024",
    "periodMonths": 12
  },
  "vehicle": {
    "licensePlate": "В738НМ82",
    "vin": "XF0VXXBDFV5G63568",
    "chassisNumber": "",
    "bodyNumber": "",
    "make": "Ford",
    "model": "Transit",
    "category": "B",
    "productionYear": "2005",
    "powerHp": "101",
    "purposeCode": "1",
    "document": {
      "countryCode": "643",
      "docType": "31",
      "docSeries": "8225",
      "docNumber": "710127",
      "issueDate": "12.01.2015"
    }
  },
  "policyHolder": {
    "type": "ЮЛ",
    "fullName": "ООО \"КРЫМ ЧАЙ\"",
    "birthDate": "",
    "phone": "",
    "snils": "",
    "inn": "9102003825",
    "kpp": "",
    "address": "Респ Крым, г Симферополь, ул Бородина, д 20А",
    "email": "john@lenin.su",
    "document": {
      "countryCode": "643",
      "docType": "62",
      "docSeries": "23",
      "docNumber": "008837510",
      "issueDate": "20.05.2014",
      "issuedBy": ""
    }
  },
  "owner": {
    "type": "ФЛ",
    "fullName": "Родионова Людмила Григорьевна",
    "birthDate": "04.12.1946",
    "phone": "",
    "snils": "",
    "inn": "",
    "kpp": "",
    "address": "Респ Крым, г Симферополь, ул Воровского, д 60, кв 230",
    "email": "",
    "document": {
      "countryCode": "643",
      "docType": "12",
      "docSeries": "3914",
      "docNumber": "218449",
      "issueDate": "05.06.2014",
      "issuedBy": "ФМС"
    }
  },
  "drivers": [
    {
      "Name": "Лазарев Александр Александрович",
      "birthDate": "29.06.1989",
      "firstLicensedDate": "16.02.2009",
      "document": {
        "countryCode": "643",
        "docType": "20",
        "docSeries": "9903",
        "docNumber": "560197"
      }
    },
    {
      "Name": "Древетняк Руслан Алексеевич",
      "birthDate": "29.09.1983",
      "firstLicensedDate": "22.10.2008",
      "document": {
        "countryCode": "643",
        "docType": "20",
        "docSeries": "8225",
        "docNumber": "881212"
      }
    }
  ]
};

Map<String, dynamic> testDataGood = {
  "insuranceContract": {
    "dateActionBeg": "16.03.2024",
    "periodMonths": 12
  },
  "vehicle": {
    "licensePlate": "В777НМ82",
    "vin": "XF0VXXBDFV5G63668",
    "chassisNumber": "",
    "bodyNumber": "",
    "make": "Ford",
    "model": "Transit",
    "category": "B",
    "productionYear": "2009",
    "powerHp": "101",
    "purposeCode": "1",
    "document": {
      "countryCode": "643",
      "docType": "31",
      "docSeries": "8335",
      "docNumber": "713327",
      "issueDate": "12.03.2015"
    }
  },
  "policyHolder": {
    "type": "ЮЛ",
    "fullName": "ООО \"НЕЕЕТ\"",
    "birthDate": "",
    "phone": "",
    "inn": "9102003825",
    "kpp": "784201007",
    "address": "г Санкт-Петербург, ул Воскова, д 1, кв 2",
    "email": "john@lenin.su",
    "document": {
      "countryCode": "643",
      "docType": "62",
      "docSeries": "22",
      "docNumber": "008833333",
      "issueDate": "21.04.2012",
      "issuedBy": ""
    }
  },
  "owner": {
    "type": "ФЛ",
    "fullName": "Пушкина Людмила Сергеевна",
    "birthDate": "01.11.1976",
    "phone": "79115556677",
    "inn": "",
    "kpp": "",
    "address": "г Санкт-Петербург, ул Воскова, д 1, кв 3",
    "email": "qwerty@mail.ru",
    "document": {
      "countryCode": "643",
      "docType": "12",
      "docSeries": "1111",
      "docNumber": "233449",
      "issueDate": "05.11.2015",
      "issuedBy": "КАЛИНИНСКИМ РАЙОННЫМ УВД Г. УФЫ"
    }
  },
  "drivers": [
    {
      "Name": "Лазарев Сергей Александрович",
      "birthDate": "19.04.1988",
      "firstLicensedDate": "11.02.2009",
      "document": {
        "countryCode": "643",
        "docType": "20",
        "docSeries": "3333",
        "docNumber": "444444"
      }
    },
    {
      "Name": "Ефимов Руслан Алексеевич",
      "birthDate": "29.09.1982",
      "firstLicensedDate": "22.10.2001",
      "document": {
        "countryCode": "643",
        "docType": "20",
        "docSeries": "4545",
        "docNumber": "363636"
      }
    }
  ]
};