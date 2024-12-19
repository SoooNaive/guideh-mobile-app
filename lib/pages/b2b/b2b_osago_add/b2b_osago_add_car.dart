import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:intl/intl.dart';

import 'b2b_osago_add.dart';

class B2BOsagoAddCar extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Function(List<String>, String) updatePhotos;
  final List<String>? photos;
  const B2BOsagoAddCar({
    super.key,
    required this.data,
    this.photos,
    required this.updatePhotos,
  });

  @override
  State<B2BOsagoAddCar> createState() => _B2BOsagoAddCarState();
}

class _B2BOsagoAddCarState extends State<B2BOsagoAddCar> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _stsCarNumberCtrl = TextEditingController();
  final TextEditingController _stsVinNumberCtrl = TextEditingController();
  final TextEditingController _stsCarChassisNumberCtrl = TextEditingController();
  final TextEditingController _stsCarTrailerNumberCtrl = TextEditingController();
  final TextEditingController _stsCarBrandCtrl = TextEditingController();
  final TextEditingController _stsCarModelCtrl = TextEditingController();
  final TextEditingController _stsCarYearCtrl = TextEditingController();
  final TextEditingController _stsNumberCtrl = TextEditingController();
  final TextEditingController _stsPowerHpCtrl = TextEditingController();
  final TextEditingController _stsIssueDateCtrl = TextEditingController();

  String? _selectedCategory = 'B';
  final List<String> _categoryOptions = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _stsCarNumberCtrl.text = widget.data!['licensePlate'] ?? '';
      _stsVinNumberCtrl.text = widget.data!['vin'] ?? '';
      _stsCarChassisNumberCtrl.text = widget.data!['chassisNumber'] ?? '';
      _stsCarTrailerNumberCtrl.text = widget.data!['bodyNumber'] ?? '';
      _stsCarBrandCtrl.text = widget.data!['make'] ?? '';
      _stsCarModelCtrl.text = widget.data!['model'] ?? '';
      _stsCarYearCtrl.text = widget.data!['productionYear'] ?? '';
      _stsNumberCtrl.text = (widget.data!['document']?['docSeries'] + widget.data!['document']?['docNumber']) ?? '';
      _selectedCategory = widget.data!['category'] ?? '';
      _stsPowerHpCtrl.text = widget.data!['powerHp'] ?? '';
      _stsIssueDateCtrl.text = widget.data!['document']?['issueDate'] ?? '';
    }
    if (widget.photos != null && widget.photos!.isNotEmpty) {
      _photoPath = widget.photos?[0];
    }
  }

  String? _photoPath;
  bool _isRecognizing = false;

  _handleCamera(String imagePath) async {
    setState(() {
      _isRecognizing = true;
      _photoPath = imagePath;
    });
    await B2BOsagoAdd.getVision('vehicle-registration-front', imagePath, _handleVision);
    setState(() => _isRecognizing = false);
  }

  Future<bool> _handleVision(List<dynamic> pages) async {
    if (pages[0]['entities'] == null) {
      print('Ошибка распознования: entities в 1-й странице is null');
      return false;
    }
    if (pages[0]['entities'].length == 0) {
      print('Ошибка распознования: нет entities в 1-й странице');
      return false;
    }
    if (pages.length != 1) {
      print('! WARN: decoded json from YA VISION: кол-во страниц не 1, а ${pages.length}');
    }

    // чистим форму
    _formKey.currentState!.reset();
    _stsCarNumberCtrl.clear();
    _selectedCategory = null;
    _stsVinNumberCtrl.clear();
    _stsCarBrandCtrl.clear();
    _stsCarModelCtrl.clear();
    _stsCarYearCtrl.clear();
    _stsPowerHpCtrl.clear();
    _stsCarChassisNumberCtrl.clear();
    _stsCarTrailerNumberCtrl.clear();
    _stsNumberCtrl.clear();
    _stsIssueDateCtrl.clear();

    String? grz;
    for (Map<String, dynamic> entity in pages[0]['entities']) {
      switch (entity['name']) {
        case 'stsfront_car_number':
          _stsCarNumberCtrl.text = entity['text'].toUpperCase() ?? '';
          grz = entity['text'];
          break;
        case 'stsfront_vin_number': _stsVinNumberCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'stsfront_car_brand': _stsCarBrandCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'stsfront_car_model': _stsCarModelCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'stsfront_car_year': _stsCarYearCtrl.text = entity['text'] ?? ''; break;
        case 'stsfront_car_chassis_number': _stsCarChassisNumberCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'stsfront_car_trailer_number': _stsCarTrailerNumberCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'stsfront_sts_number': _stsNumberCtrl.text = entity['text'] ?? ''; break;
      }
    }

    // стучимся в автокод, чтобы подставить категорию, мощность и дату выдачи СТС
    if (grz != null) {
      final autocodeResponse = await Http.mobApp(
          ApiParams('GD_Service', 'Autocod', {
            'Method': 'ReportGRZ',
            'GRZ': grz,
          })
      );
      final Map<String, dynamic>? data = autocodeResponse?['data']?[0]['content'];
      final String? vehicleCategory = data?['additional_info']['vehicle']['category']['code'];
      final String? vehiclePowerHp = data?['tech_data']['engine']['power']['hp'].toString();
      final String? vehicleDocumentStsIssueDate = data?['additional_info']['vehicle']['sts']['date']['receive'];
      if (vehicleCategory != null) {
        if (_categoryOptions.contains(vehicleCategory)) {
          _selectedCategory = vehicleCategory;
        }
      }
      if (vehiclePowerHp != null) _stsPowerHpCtrl.text = vehiclePowerHp;
      if (vehicleDocumentStsIssueDate != null) {
        DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        _stsIssueDateCtrl.text = DateFormat('dd.MM.yyyy').format(dateFormat.parse(vehicleDocumentStsIssueDate));
      }
    }

    setState(() { });

    await Future.delayed(const Duration(milliseconds: 10));
    _formKey.currentState!.validate();

    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Транспортное средство'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Данные СТС',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (_isRecognizing) return;
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TakePhoto(
                                          addPhoto: _handleCamera,
                                          locationRequired: false,
                                          template: TakePhotoTemplate.sts,
                                        ),
                                      )
                                  );
                                },
                                icon: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: _isRecognizing
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  )
                                      : const Icon(Icons.document_scanner_outlined),
                                ),
                                label: const Text('Сканировать'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecognizing
                                      ? const Color(0xffaaaaaa)
                                      : secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stsCarNumberCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Рег. знак',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите ГРЗ';
                                    }
                                    return null;
                                  },
                                  enabled: !_isRecognizing,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: DropdownButtonFormField(
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  padding: const EdgeInsets.only(top: 4),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Категория ТС',
                                  ),
                                  hint: const Text('Выберите'),
                                  onChanged: _isRecognizing ? null : (value) {
                                    setState(() => _selectedCategory = value! as String);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите категорию';
                                    }
                                    return null;
                                  },
                                  value: _selectedCategory,
                                  items: _categoryOptions
                                    .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _stsVinNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'VIN-номер',
                            ),
                            minLines: 1,
                            maxLines: 2,
                            enabled: !_isRecognizing,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stsCarBrandCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Марка',
                                  ),
                                  minLines: 1,
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите марку';
                                    }
                                    return null;
                                  },
                                  enabled: !_isRecognizing,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextFormField(
                                  controller: _stsCarModelCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Модель',
                                  ),
                                  minLines: 1,
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите модель';
                                    }
                                    return null;
                                  },
                                  enabled: !_isRecognizing,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stsCarYearCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Год выпуска',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите год выпуска';
                                    }
                                    if (value.length != 4) {
                                      return 'Некорректный формат';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  enabled: !_isRecognizing,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextFormField(
                                  controller: _stsPowerHpCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: "Мощность, л/с",
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите мощность';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  enabled: !_isRecognizing,
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _stsCarChassisNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Номер шасси',
                            ),
                            minLines: 1,
                            maxLines: 2,
                            enabled: !_isRecognizing,
                          ),
                          TextFormField(
                            controller: _stsCarTrailerNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Номер кузова, кабины или прицепа',
                            ),
                            minLines: 1,
                            maxLines: 2,
                            enabled: !_isRecognizing,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stsNumberCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Серия, номер СТС',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите серию и номер';
                                    }
                                    if (value.length < 5) {
                                      return 'Неверный формат';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  enabled: !_isRecognizing,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextFormField(
                                  controller: _stsIssueDateCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: const InputDecoration(
                                    labelText: 'Дата выдачи СТС',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Укажите дату выдачи';
                                    }
                                    if (value.length < 10) {
                                      return 'Некорректный формат даты';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [DateTextFormatter()],
                                  maxLength: 10,
                                  enabled: !_isRecognizing,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (_photoPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xff555560),
                          ),
                          width: double.infinity,
                          child: Image.file(
                            File(_photoPath!),
                            height: 200,
                          ),
                        ),
                      ),

                  ],
                ),
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
                  child: TextButton.icon(
                    style: getTextButtonStyle(),
                    onPressed: _isRecognizing ? null : () {

                      // валидация
                      if (!_formKey.currentState!.validate()) return;
                      if (_stsVinNumberCtrl.text == '' &&
                          _stsCarChassisNumberCtrl.text == '' &&
                          _stsCarTrailerNumberCtrl.text == '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              showCloseIcon: true,
                              closeIconColor: Colors.white,
                              content: Text('Необходимо заполнить хотя бы одно из полей:\n — VIN-номер\n — Номер шасси\n — Номер кузова')
                          ),
                        );
                        return;
                      }

                      // фотки
                      if (_photoPath != null) {
                        widget.updatePhotos([_photoPath!], 'vehicle');
                      }

                      context.pop({
                        'licensePlate': _stsCarNumberCtrl.text,
                        'vin': _stsVinNumberCtrl.text,
                        'chassisNumber': _stsCarChassisNumberCtrl.text != 'ОТСУТСТВУЕТ' ? _stsCarChassisNumberCtrl.text : '',
                        'bodyNumber': _stsCarTrailerNumberCtrl.text,
                        'make': _stsCarBrandCtrl.text,
                        'model': _stsCarModelCtrl.text,
                        'category': _selectedCategory,
                        'productionYear': _stsCarYearCtrl.text,
                        'powerHp': _stsPowerHpCtrl.text,
                        'purposeCode': '1',
                        'document': {
                          'countryCode': '643',
                          'docType': '31',
                          'docSeries': _stsNumberCtrl.text.replaceAll(' ', '').substring(0, 4),
                          'docNumber': _stsNumberCtrl.text.replaceAll(' ', '').substring(4),
                          'issueDate': _stsIssueDateCtrl.text,
                        },
                      });
                    },
                    label: const Text('Сохранить'),
                    icon: const Icon(Icons.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
