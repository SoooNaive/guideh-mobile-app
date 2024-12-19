import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/api_dadata.dart';
import 'package:guideh/services/format_date.dart';
import 'package:guideh/services/format_phone.dart';
import 'package:guideh/theme/theme.dart';

import 'b2b_osago_add.dart';

class B2BOsagoAddPerson extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String personType;
  final bool? ownerIsInsurer;
  final Function? getOwnerIsInsurer;
  final Function(List<String>, String) updatePhotos;
  final List<String>? photos;
  const B2BOsagoAddPerson({
    super.key,
    required this.data,
    required this.personType,
    this.ownerIsInsurer,
    this.getOwnerIsInsurer,
    this.photos,
    required this.updatePhotos,
  });

  @override
  State<B2BOsagoAddPerson> createState() => _B2BOsagoAddPersonState();
}

class _B2BOsagoAddPersonState extends State<B2BOsagoAddPerson> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _patronymicCtrl = TextEditingController();
  final TextEditingController _docNumber = TextEditingController();
  final TextEditingController _birthdateCtrl = TextEditingController();
  final TextEditingController _issueDateCtrl = TextEditingController();
  final TextEditingController _issuedByCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  final _addressKey = GlobalKey<FormFieldState>();
  final SuggestionsController<String> _addressSuggestionsCtrl = SuggestionsController();

  bool addressIsValid = false;
  String? _photoPath;
  bool _ownerIsInsurer = false;
  bool _isRecognizing = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _fillForm(widget.data);
      addressIsValid = true;
    }
    _ownerIsInsurer = widget.ownerIsInsurer ?? false;
    if (widget.photos != null && widget.photos!.isNotEmpty) {
      _photoPath = widget.photos?[0];
    }
  }

  // заполняем форму
  void _fillForm(Map<String, dynamic>? policyHolderData) {
    if (policyHolderData == null) {
      _nameCtrl.clear();
      _surnameCtrl.clear();
      _patronymicCtrl.clear();
      _docNumber.clear();
      _birthdateCtrl.clear();
      _issueDateCtrl.clear();
      _issuedByCtrl.clear();
      _addressCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _formKey.currentState!.validate();
      return;
    }
    final nameParts = policyHolderData['fullName'].split(' ');
    _nameCtrl.text = nameParts[1] ?? '';
    _surnameCtrl.text = nameParts[0] ?? '';
    _patronymicCtrl.text = nameParts[2] ?? '';
    _docNumber.text = (policyHolderData['document']?['docSeries'] + policyHolderData['document']?['docNumber']) ?? '';
    _birthdateCtrl.text = policyHolderData['birthDate'] ?? '';
    _issueDateCtrl.text = policyHolderData['document']?['issueDate'] ?? '';
    _issuedByCtrl.text = policyHolderData['document']?['issuedBy'] ?? '';
    _addressCtrl.text = policyHolderData['address'] ?? '';
    _phoneCtrl.text = policyHolderData['phone'] ?? '';
    _emailCtrl.text = policyHolderData['email'] ?? '';
  }

  _handleCamera(String imagePath) async {
    setState(() {
      _isRecognizing = true;
      _photoPath = imagePath;
    });
    await B2BOsagoAdd.getVision('passport', imagePath, _handleVision);
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
    _nameCtrl.clear();
    _surnameCtrl.clear();
    _patronymicCtrl.clear();
    _birthdateCtrl.clear();
    _issuedByCtrl.clear();
    _issueDateCtrl.clear();
    _docNumber.clear();
    _addressCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();

    for (Map<String, dynamic> entity in pages[0]['entities']) {
      switch (entity['name']) {
        case 'surname': _surnameCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'name': _nameCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'middle_name': _patronymicCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'birth_date': _birthdateCtrl.text = entity['text'] ?? ''; break;
        case 'number':
          if (entity['text'].length == 10) {
            _docNumber.text = '${entity['text']?.substring(0, 4)} ${entity['text']?.substring(4, 10)}';
          }
          else {
            _docNumber.text = entity['text'];
          }
          break;
        case 'issued_by': _issuedByCtrl.text = entity['text'].toUpperCase() ?? ''; break;
        case 'issue_date': _issueDateCtrl.text = entity['text'] ?? ''; break;
      }
    }
    _formKey.currentState!.validate();
    setState(() { });

    return true;
  }

  void _triggerOwnerIsInsurer() {
    final policyHolderData = widget.getOwnerIsInsurer!();
    if (!_ownerIsInsurer) {
      if (policyHolderData != null) {
        _fillForm(policyHolderData);
        setState(() => _ownerIsInsurer = true);
      }
      else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            showCloseIcon: true,
            closeIconColor: Colors.white,
            content: Text('Данные Страхователя не заполнены'),
          ),
        );
      }
    }
    else {
      _fillForm(null);
      setState(() => _ownerIsInsurer = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool lockForm = _ownerIsInsurer || _isRecognizing;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.personType == 'policyHolder' ? 'Страхователь' : 'Собственник'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.personType == 'owner') Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                        child: Row(
                          children: [
                            Switch(
                              value: _ownerIsInsurer,
                              onChanged: _isRecognizing ? null : (bool enable) {
                                _triggerOwnerIsInsurer();
                              },
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: _isRecognizing ? null : () {
                                  _triggerOwnerIsInsurer();
                                },
                                child: const Text('Страхователь является собственником'),
                              )
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
                                      'Паспорт',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: lockForm ? null : () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TakePhoto(
                                            addPhoto: _handleCamera,
                                            locationRequired: false,
                                            template: TakePhotoTemplate.passport,
                                          ),
                                        )
                                      );
                                    },
                                    icon: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: _isRecognizing
                                        ? CircularProgressIndicator(
                                          color: _isRecognizing ? Colors.black26 : Colors.white,
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
                                      enabled: !lockForm,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
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
                                      enabled: !lockForm,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
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
                                      enabled: !lockForm,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _birthdateCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Дата рождения',
                                        counterText: '',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Укажите дату';
                                        }
                                        if (value.length < 10) {
                                          return 'Неверный формат даты';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [DateTextFormatter()],
                                      maxLength: 10,
                                      enabled: !lockForm,
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: _issuedByCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: const InputDecoration(
                                  labelText: 'Паспорт выдан',
                                ),
                                minLines: 1,
                                maxLines: 6,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Укажите, кем выдан паспорт';
                                  }
                                  return null;
                                },
                                enabled: !lockForm,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _issueDateCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Дата выдачи',
                                        counterText: '',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Укажите дату';
                                        }
                                        if (value.length < 10) {
                                          return 'Неверный формат даты';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [DateTextFormatter()],
                                      maxLength: 10,
                                      enabled: !lockForm,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
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
                                      enabled: !lockForm,
                                    ),
                                  ),
                                ],
                              ),

                              TypeAheadField<String>(
                                autoFlipDirection: true,
                                controller: _addressCtrl,
                                suggestionsCallback: (search) => DaData.search(search),
                                suggestionsController: _addressSuggestionsCtrl,
                                debounceDuration: const Duration(milliseconds: 500),
                                builder: (context, controller, focusNode) {
                                  return TextFormField(
                                    key: _addressKey,
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: const InputDecoration(
                                      labelText: 'Адрес',
                                      // helperText: _addressCtrl.text != ''
                                      //   ? (addressIsValid ? 'Адрес корректный' : 'Выберите адрес из списка')
                                      //   : null,
                                      // helperStyle: TextStyle(
                                      //   color: addressIsValid ? Colors.green : Colors.red
                                      // )
                                    ),
                                    minLines: 1,
                                    maxLines: 4,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Укажите адрес';
                                      }
                                      if (!addressIsValid) {
                                        return 'Адрес некорректный. Выберите из списка.';
                                      }
                                      return null;
                                    },
                                    onChanged: (address) {
                                      if (addressIsValid) setState(() => addressIsValid = false);
                                    },
                                    enabled: !lockForm,
                                  );
                                },
                                itemBuilder: (context, address) => DaData.tile(address),
                                itemSeparatorBuilder: (_, __) => const Divider(height: 1),
                                onSelected: (address) async {
                                  setState(() {
                                    _addressCtrl.text = address;
                                    addressIsValid = true;
                                  });
                                  _addressKey.currentState?.validate();
                                  _addressSuggestionsCtrl.unfocus();
                                },
                                loadingBuilder: (context) => DaData.tile('Поиск...'),
                                errorBuilder: (context, error) => DaData.tile('Ошибка поиска'),
                                hideOnEmpty: true,
                              ),

                              if (widget.personType == 'policyHolder') Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(
                                        labelText: 'Телефон',
                                        prefixText: '+7',
                                      ),
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [phoneInputFormatter],
                                      validator: (value) {
                                        if (value!.isEmpty) return 'Введите номер телефона';
                                        if (value.length < 16) return 'Неверный формат номера';
                                        return null;
                                      },
                                      enabled: !lockForm,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      decoration: const InputDecoration(labelText: 'Email'),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) => value!.isEmpty ? 'Введите адрес эл. почты' : null,
                                      enabled: !lockForm,
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
                  child: TextButton.icon(
                    style: getTextButtonStyle(),
                    onPressed: _isRecognizing ? null : () {

                      // валидация
                      if (!_formKey.currentState!.validate() && !_ownerIsInsurer) return;

                      // фотки
                      if (_photoPath != null) {
                        widget.updatePhotos([_photoPath!], widget.personType);
                      }

                      context.pop({
                        'type': 'ФЛ',
                        'fullName': '${_surnameCtrl.text} ${_nameCtrl.text} ${_patronymicCtrl.text}',
                        'birthDate': _birthdateCtrl.text,
                        'document': {
                          'countryCode': '643',
                          'docType': '12',
                          'docSeries': _docNumber.text.replaceAll(' ', '').substring(0, 4),
                          'docNumber': _docNumber.text.replaceAll(' ', '').substring(4),
                          'issueDate': _issueDateCtrl.text,
                          'issuedBy': _issuedByCtrl.text,
                        },
                        'phone': _phoneCtrl.text,
                        'email': _emailCtrl.text,
                        'address': _addressCtrl.text,
                        'inn': '',
                        'kpp': '',
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
