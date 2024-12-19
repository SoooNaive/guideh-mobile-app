import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/theme/theme.dart';

import 'b2b_osago_add.dart';

class B2BOsagoAddDriver extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? policyHolderData;
  final Map<String, dynamic>? ownerData;
  final bool ownerIsInsurer;
  final bool policyHolderIsDriver;
  final bool ownerIsDriver;
  final int driverIndex;
  final Function(int)? deleteDriver;
  final List<String>? photosDriver;
  final Function(List<String>, int) updatePhotosDrivers;
  const B2BOsagoAddDriver({
    super.key,
    required this.data,
    required this.policyHolderData,
    required this.ownerData,
    required this.ownerIsInsurer,
    required this.policyHolderIsDriver,
    required this.ownerIsDriver,
    required this.driverIndex,
    this.deleteDriver,
    this.photosDriver,
    required this.updatePhotosDrivers,
  });

  @override
  State<B2BOsagoAddDriver> createState() => _B2BOsagoAddDriverState();
}

class _B2BOsagoAddDriverState extends State<B2BOsagoAddDriver> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _patronymicCtrl = TextEditingController();
  final TextEditingController _docNumber = TextEditingController();
  final TextEditingController _birthdateCtrl = TextEditingController();
  final TextEditingController _firstLicensedDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      final nameParts = widget.data!['name'].split(' ');
      _nameCtrl.text = nameParts[1] ?? '';
      _surnameCtrl.text = nameParts[0] ?? '';
      _patronymicCtrl.text = nameParts[2] ?? '';
      _docNumber.text
        = (widget.data!['document']?['docSeries'] + widget.data!['document']?['docNumber']) ?? '';
      _birthdateCtrl.text = widget.data!['birthDate'] ?? '';
      _firstLicensedDateCtrl.text = widget.data!['firstLicensedDate'].substring(6) ?? '';
    }
    if (widget.photosDriver != null && widget.photosDriver!.isNotEmpty) {
      _photoPathFront = widget.photosDriver?[0];
      _photoPathBack = widget.photosDriver?[1];
    }
  }

  String? _photoPathFront;
  String? _photoPathBack;
  bool _isRecognizing = false;


  // 1: take photo front
  Future<dynamic> _takePhotoFront() async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePhoto(
          addPhoto: _handleCameraFront,
          locationRequired: false,
          template: TakePhotoTemplate.driverLicenseFront,
        ),
      )
    );
  }

  // 2: handle photo front
  void _handleCameraFront(String imagePath) {
    _photoPathFront = imagePath;
  }

  // 3: take photo back
  Future<dynamic> _takePhotoBack() async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePhoto(
          addPhoto: _handleCameraBack,
          locationRequired: false,
          template: TakePhotoTemplate.driverLicenseBack,
        ),
      )
    );
  }

  // 4: handle photo back
  void _handleCameraBack(String imagePath) {
    _photoPathBack = imagePath;
  }

  // recognize photos
  _handleVision() async {

    // чистим форму
    _formKey.currentState!.reset();
    _surnameCtrl.clear();
    _nameCtrl.clear();
    _patronymicCtrl.clear();
    _birthdateCtrl.clear();
    _docNumber.clear();
    _firstLicensedDateCtrl.clear();

    if (_photoPathFront != null) {
      await B2BOsagoAdd.getVision('driver-license-front', _photoPathFront!, _handleVisionFront);
    }
    if (_photoPathBack != null) {
      await B2BOsagoAdd.getVision('driver-license-back', _photoPathBack!, _handleVisionBack);
    }

    _formKey.currentState!.validate();
    return true;
  }

  // vision validate
  bool _validateVision(List<dynamic> pages) {
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
    return true;
  }

  // recognize front
  Future<void> _handleVisionFront(List<dynamic> pages) async {
    if (!_validateVision(pages)) return;
    for (Map<String, dynamic> entity in pages[0]['entities']) {
      switch (entity['name']) {
        case 'name': _nameCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'surname': _surnameCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'middle_name': _patronymicCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'birth_date': _birthdateCtrl.text = entity['text'] ?? ''; break;
        case 'number':
          if (entity['text'].length == 10) {
            _docNumber.text = (entity['text'].substring(0, 2)
                + ' ${entity['text'].substring(2, 4)}'
                + ' ${entity['text'].substring(4, 10)}') ?? '';
          }
          else {
            _docNumber.text = entity['text'];
          }
          break;
      }
    }
  }

  // recognize back
  Future<void> _handleVisionBack(List<dynamic> pages) async {
    if (!_validateVision(pages)) return;
    for (Map<String, dynamic> entity in pages[0]['entities']) {
      switch (entity['name']) {
        case 'experience_from': _firstLicensedDateCtrl.text = entity['text'] ?? ''; break;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool showClonePolicyHolderButton =
        widget.policyHolderData != null && !widget.policyHolderIsDriver;
    final bool showCloneOwnerButton =
        widget.ownerData != null && !widget.ownerIsDriver && !widget.ownerIsInsurer;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Водитель'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (showClonePolicyHolderButton || showCloneOwnerButton) Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            if (showClonePolicyHolderButton) ElevatedButton.icon(
                              onPressed: _isRecognizing ? null : () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      content: const Text('Добавить страхователя в качестве водителя?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Отмена'),
                                          onPressed: () => dialogContext.pop(),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final nameParts = widget.policyHolderData?['fullName'].split(' ');
                                            _nameCtrl.text = nameParts[1] ?? '';
                                            _surnameCtrl.text = nameParts[0] ?? '';
                                            _patronymicCtrl.text = nameParts[2] ?? '';
                                            _docNumber.text
                                              = ((widget.policyHolderData?['document']['docSeries'] ?? '') + (widget.policyHolderData?['document']['docNumber'] ?? ''));
                                            _birthdateCtrl.text = widget.policyHolderData?['birthDate'] ?? '';
                                            _firstLicensedDateCtrl.text = '';
                                            dialogContext.pop();
                                          },
                                          child: const Text('Добавить'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.copy_all),
                              label: const Text('Вставить данные страхователя'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                disabledBackgroundColor: secondaryColor,
                                disabledForegroundColor: Colors.white24,
                                alignment: Alignment.centerLeft,
                              ),
                            ),

                            if (showClonePolicyHolderButton && showCloneOwnerButton)
                              const SizedBox(height: 4),

                            if (showCloneOwnerButton) ElevatedButton.icon(
                              onPressed: _isRecognizing ? null : () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      content: const Text('Добавить собственника в качестве водителя?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Отмена'),
                                          onPressed: () => dialogContext.pop(),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final nameParts = widget.ownerData?['fullName'].split(' ');
                                            _nameCtrl.text = nameParts[1] ?? '';
                                            _surnameCtrl.text = nameParts[0] ?? '';
                                            _patronymicCtrl.text = nameParts[2] ?? '';
                                            _docNumber.text
                                            = ((widget.ownerData?['document']['docSeries'] ?? '') + (widget.ownerData?['document']['docNumber'] ?? ''));
                                            _birthdateCtrl.text = widget.ownerData?['birthDate'] ?? '';
                                            _firstLicensedDateCtrl.text = '';
                                            dialogContext.pop();
                                          },
                                          child: const Text('Добавить'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.copy_all),
                              label: const Text('Вставить данные собственника'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                disabledBackgroundColor: secondaryColor,
                                disabledForegroundColor: Colors.white24,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                  Padding(
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
                                      'Водительское удостоверение',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (_isRecognizing) return;
                                      setState(() => _isRecognizing = true);
                                      // front
                                      final dynamic takePhotoFrontResponse = await _takePhotoFront();
                                      if (takePhotoFrontResponse == null) {
                                        setState(() => _isRecognizing = false);
                                        return;
                                      }
                                      //delay
                                      await Future.delayed(const Duration(seconds: 3));
                                      //back
                                      final dynamic takePhotoBackResponse = await _takePhotoBack();
                                      if (takePhotoBackResponse == null) {
                                        setState(() {
                                          // очистим и первую фотку
                                          _photoPathFront = null;
                                          _isRecognizing = false;
                                        });
                                        return;
                                      }
                                      await _handleVision();
                                      setState(() => _isRecognizing = false);
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
                              TextFormField(
                                controller: _surnameCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  labelText: 'Фамилия',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Укажите фамилию';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.name,
                                enabled: !_isRecognizing,
                              ),
                              TextFormField(
                                controller: _nameCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  labelText: 'Имя',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Укажите имя';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.name,
                                enabled: !_isRecognizing,
                              ),
                              TextFormField(
                                controller: _patronymicCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  labelText: 'Отчество',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Укажите отчество';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.name,
                                enabled: !_isRecognizing,
                              ),
                              TextFormField(
                                controller: _birthdateCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  labelText: 'Дата рождения',
                                  counterText: '',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Укажите дату рождения';
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
                              Row(
                                children: [
                                  Flexible(
                                    flex: 8,
                                    child: TextFormField(
                                      controller: _docNumber,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Серия номер',
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
                                  Flexible(
                                    flex: 9,
                                    child: TextFormField(
                                      controller: _firstLicensedDateCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Год начала стажа',
                                        counterText: '',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Укажите год начала стажа';
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
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_photoPathFront != null || _photoPathBack != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xff555560),
                              ),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_photoPathFront != null) Image.file(
                                    File(_photoPathFront!),
                                    height: 200,
                                  ),
                                  if (_photoPathFront != null && _photoPathBack != null) const SizedBox(width: 8),
                                  if (_photoPathBack != null) Image.file(
                                    File(_photoPathBack!),
                                    height: 200,
                                  ),
                                ],
                              ),
                            ),
                          ),

                      ],
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
                  child: Row(
                    children: [
                      if (widget.data != null) Expanded(
                        child: TextButton.icon(
                          style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                          onPressed: _isRecognizing ? null : () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  content: const Text('Добавить страхователя в качестве водителя?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => dialogContext.pop(false),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () => dialogContext.pop(true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm) {
                              widget.deleteDriver!(widget.driverIndex);
                              if (context.mounted) {
                                context.pop();
                              }
                            }
                          },
                          label: const Text('Удалить'),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                      if (widget.data != null) const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          style: getTextButtonStyle(),
                          onPressed: _isRecognizing ? null : () {

                            // валидация
                            if (!_formKey.currentState!.validate()) return;

                            // обновим фотки
                            List<String> photos = [];
                            if (_photoPathFront != null && _photoPathBack != null) {
                              photos.addAll([_photoPathFront!, _photoPathBack!]);
                            }
                            widget.updatePhotosDrivers(photos, widget.driverIndex);

                            context.pop({
                              'name': '${_surnameCtrl.text} ${_nameCtrl.text} ${_patronymicCtrl.text}',
                              'birthDate': _birthdateCtrl.text,
                              'firstLicensedDate': '01.01.${_firstLicensedDateCtrl.text}',
                              'document': {
                                'countryCode': '643',
                                'docType': '20',
                                'docSeries': _docNumber.text.replaceAll(' ', '').substring(0, 4),
                                'docNumber': _docNumber.text.replaceAll(' ', '').substring(4),
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
          ),
        ],
      ),
    );
  }
}
