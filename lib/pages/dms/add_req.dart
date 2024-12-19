import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/dms/letters_of_guarantee/guarantee_letters_models.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/format_email.dart';
import 'package:guideh/services/format_phone.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/services/validators/date_validator.dart';
import 'package:guideh/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'lpu_list.dart';
import 'models/lpu.dart';

class AddReq extends StatefulWidget {
  final String policyId;
  final DmsLpu? lpu;
  const AddReq({super.key, required this.policyId, this.lpu});

  @override
  State<AddReq> createState() => _AddReq();
}

class _AddReq extends State<AddReq> with SingleTickerProviderStateMixin {
  DmsLpu? lpu;

  final String lpuPlaceholder = 'Выберите клинику';

  final dmsAppointmentFormKey = GlobalKey<FormState>();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _lpuController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final timeController = MultiSelectController<String>();

  DmsLetterRequestCountType? _requestCountType;
  DmsLetterRequestType? _requestType;
  DmsLetterContactType? _contactType;

  late List<DmsLetterRequestCountType> _requestCountTypes;
  late List<DmsLetterRequestType> _requestTypes;
  late List<DmsLetterContactType> _contactTypes;

  bool _requestCountTypeError = false;
  bool _requestTypeError = false;
  bool _contactTypeError = false;

  bool formIsLoading = false;

  // файлы
  final List<File> _selectedFiles = [];
  final List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'msg'];
  final int _maxFileSize = 25 * 1024 * 1024; // 25 MB
  final int _maxFileCount = 10;

  void _pickFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: true,
        compressionQuality: 75,
      );
      if (result != null) {
        final files = result.files.map((file) => File(file.path!)).toList();
        for (final file in files) {
          final fileSize = await file.length();
          if (fileSize > _maxFileSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Превышен мах. размер одного файла - 25 мб: ${path.basename(file.path)}')),
              );
            }
            continue;
          }
          if (_selectedFiles.length >= _maxFileCount) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Превышено мах. количество файлов - 10.')),
              );
              break;
            }
          }
          setState(() => _selectedFiles.add(file));
        }
      }
    } catch (e) {
      print('Ошибка при выборе файлов: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе файлов')),
        );
      }
    }
  }

  void _removeFile(int index) => setState(() => _selectedFiles.removeAt(index));

  Widget _buildFileItem(int fileIndex) {
    final File file = _selectedFiles[fileIndex];
    final fileName = path.basename(file.path);
    final fileExtension = fileName.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png'].contains(fileExtension);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Миниатюра изображения или расширение файла
        Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: isImage ? null : Colors.black12,
            borderRadius: BorderRadius.circular(5),
          ),
          clipBehavior: Clip.hardEdge,
          child: isImage
              ? Image.file(file, fit: BoxFit.cover)
              : Center(
            child: Text(
              fileExtension.toUpperCase(),
              style: TextStyle(color: Color(0xFF444444), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Название файла
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14),
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: () => _removeFile(fileIndex),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }


  Future<void> _loadDefaultContacts() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? phone = preferences.getString('DMSPhone');
    final String? email = preferences.getString('DMSEmail');
    _defaultContactPhone = ((phone?.trim() ?? '') != '') ? ' $phone' : '—';
    _defaultContactEmail = ((email?.trim() ?? '') != '') ? email! : '—';
  }

  // грузим справочники по этому полису
  late Future<void> _loadDictionary;
  Future<void> loadDictionary() async {
    final response = await Http.mobApp(
        ApiParams('PolicyDetails', 'MP_Catalogs', {
          'PolisId': widget.policyId
        })
    );
    _requestCountTypes = (response['DmsLetterRequestCountTypes'] as List).map((item) => DmsLetterRequestCountType(
        code: item['Code'],
        name: item['Name']
    )).toList();
    _requestTypes = (response['DmsLetterRequestTypes'] as List).map((item) => DmsLetterRequestType(
        code: item['Code'],
        name: item['Name']
    )).toList();
    _contactTypes = (response['DmsLetterContactTypes'] as List).map((item) => DmsLetterContactType(
        code: item['Code'],
        name: item['Name']
    )).toList();
  }

  // магия для мультиселекта времени
  final String _anyTimeLabel = 'Любое время';
  late final List<DropdownItem<String>> _timeSelectItems;
  // будем юзать этот массив, чтобы определить, что кликнули, в initState засунем в него _anyTimeLabel
  late List<String> _selectedTimeValues;
  // слушатель изменений
  _addTimeListener() => timeController.addListener(_timeListener);
  _removeTimeListener() => timeController.removeListener(_timeListener);
  void _timeListener() {
    // что стало
    final List<String> currentValues = timeController.selectedItems.map((item) => item.value).toList();
    // находим разницу того что было и что стало - находим на что кликнули
    final List<String> difference = [
      ...currentValues.where((item) => !_selectedTimeValues.contains(item)),
      ..._selectedTimeValues.where((item) => !currentValues.contains(item)),
    ];
    if (difference.isEmpty) return;
    // убираем на время слушатель, чтобы не впасть в стаковерфлоу
    _removeTimeListener();
    // выбрали "любое время" - чистим всё кроме этого варика (индекс 0)
    if (difference.contains(_anyTimeLabel)) {
      timeController.clearAll();
      timeController.selectAtIndex(0);
    }
    // выбрали не "любое время" - проверяем что "любое время" снято
    else if (currentValues.contains(_anyTimeLabel)) {
      timeController.unselectWhere((item) => item.value == _anyTimeLabel);
    }
    // обновляем "что было"
    final newValues = timeController.selectedItems.map((item) => item.value).toList();
    _selectedTimeValues = newValues;
    // возвращаем слушатель
    _addTimeListener();
  }

  // анимация отображения блока "смс мне/ другой номер" и т.д.
  late AnimationController contactTypeExtraBlockAnimationCtrl;
  late Animation<double> animation;
  bool _contactTypeExtraBlockIsVisible = false;
  bool _contactTypeNotMyself = false;
  List<String> _contactTypeExtraBlockLabels = ['', ''];
  bool _contactTypeExtraBlockIsClosing = false;
  late String _defaultContactPhone;
  late String _defaultContactEmail;
  final TextEditingController _otherContactController = TextEditingController()..text = '';
  void _toggleContactTypeExtraBlockVisibility(bool toggle) {
    setState(() {
      _contactTypeExtraBlockIsVisible = toggle;
      if (_contactTypeExtraBlockIsVisible) {
        contactTypeExtraBlockAnimationCtrl.forward();
      } else {
        contactTypeExtraBlockAnimationCtrl.reverse();
      }
    });
  }

  @override
  void initState() {
    if (widget.lpu == null) {
      _lpuController.text = lpuPlaceholder;
    }
    else {
      lpu = widget.lpu;
      _lpuController.text = '${lpu?.name}\n\n${lpu?.address}';
    }
    _loadDictionary = loadDictionary();
    _loadDefaultContacts();

    // для мультиселекта времени
    _addTimeListener();
    _selectedTimeValues = [_anyTimeLabel];
    _timeSelectItems = [
      DropdownItem(label: 'Любое время', value: 'Любое время', selected: true),
      DropdownItem(label: '8:00 - 12:00', value: '8:00 - 12:00'),
      DropdownItem(label: '12:00 - 16:00', value: '12:00 - 16:00'),
      DropdownItem(label: '16:00 - 21:00', value: '16:00 - 21:00'),
      DropdownItem(label: '18:00 - 21:00', value: '18:00 - 21:00'),
    ];

    // анимация отображения блока "смс мне/ другой номер" и т.д.
    contactTypeExtraBlockAnimationCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    animation = CurvedAnimation(parent: contactTypeExtraBlockAnimationCtrl, curve: Curves.easeInOutCubic);

    super.initState();
  }

  @override
  void dispose() {
    contactTypeExtraBlockAnimationCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final String polisId = widget.policyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявка на запись к врачу'), //police.DocNumber
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: FutureBuilder(
          future: _loadDictionary,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active: {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              case ConnectionState.done: {

                return Form(
                  key: dmsAppointmentFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      MultiDropdown<String>(
                        items: _timeSelectItems,
                        controller: timeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Укажите время';
                          }
                          return null;
                        },
                        fieldDecoration: FieldDecoration(
                          labelText: 'Желательное время',
                          labelStyle: const TextStyle(color: Color(0xFF999999)),
                          hintText: 'Выберите желательное время',
                          // hintStyle: const TextStyle(color: Color(0xFF999999)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: const Icon(Icons.access_time),
                          ),
                          showClearIcon: false,
                          border: UnderlineInputBorder(),
                          borderRadius: 0,
                          padding: EdgeInsets.only(bottom: 8),
                          suffixIcon: null,
                        ),
                        dropdownDecoration: DropdownDecoration(
                          elevation: 4,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        itemSeparator: Divider(height: 1, color: Color(0xFFEEEEEE)),
                        closeOnBackButton: true,
                        chipDecoration: ChipDecoration(
                          borderRadius: BorderRadius.circular(6),
                          spacing: 5,
                          runSpacing: 5,
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          labelStyle: TextStyle(fontSize: 15),
                          backgroundColor: Color(0xFFE9E9E9),
                        ),
                        enabled: !formIsLoading,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dayController,
                              enabled: !formIsLoading,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.calendar_month),
                                border: UnderlineInputBorder(),
                                labelText: 'Желательное число',
                                labelStyle: TextStyle(color: Color(0xFF999999)),
                                counterText: '',
                              ),
                              inputFormatters: [
                                MaskedInputFormatter('##.##.####',
                                  allowedCharMatcher: RegExp(r'[0-9]')
                                ),
                              ],
                              validator: (value) {
                                final String? dateValidator = dateTextValidator(value);
                                if (dateValidator != null) return dateValidator;
                                final DateTime date = DateFormat('dd.MM.yyyy').parse(value!);
                                if (date.isBefore(DateTime.now())) {
                                  return 'Дата не должна быть ранее чем сегодня';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () async {
                              final DateTime? timepickerResult = await _openDayTimePicker(context);
                              if (timepickerResult != null) {
                                setState(() {
                                  _dayController.text = DateFormat('dd.MM.yyyy').format(timepickerResult);
                                });
                              }
                            },
                            icon: Icon(Icons.calendar_month),
                            style: IconButton.styleFrom(
                              backgroundColor: primaryLightColor
                            ),
                          )
                        ],
                      ),

                      TextFormField(
                        controller: _lpuController,
                        enabled: !formIsLoading,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.domain_add),
                          border: UnderlineInputBorder(),
                          labelText: 'ЛПУ',
                          labelStyle: TextStyle(color: Color(0xFF999999)),
                          counterText: '',
                        ),
                        onTap: () => _selectLPU(context, polisId),
                        readOnly: true,
                        maxLines: null,
                      ),

                      SizedBox(height: 20),

                      // вид обращения
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Выберите вид обращения', style: TextStyle(
                              color: !_requestCountTypeError ? null : Theme.of(context).colorScheme.error,
                            )),
                            SizedBox(height: 5),
                            Wrap(
                              children: _requestCountTypes.map((item) => SizedBox(
                                width: (MediaQuery.sizeOf(context).width - 30) / 2,
                                child: RadioListTile<DmsLetterRequestCountType>(
                                  value: item,
                                  groupValue: _requestCountType,
                                  onChanged: formIsLoading ? null : (value) => setState(() {
                                    _requestCountType = value;
                                    _requestCountTypeError = false;
                                  }),
                                  title: Text(item.name),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),

                      Divider(),

                      // тип обращения
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Выберите тип обращения', style: TextStyle(
                              color: !_requestTypeError ? null : Theme.of(context).colorScheme.error,
                            )),
                            SizedBox(height: 5),
                            Wrap(
                              children: _requestTypes.map((item) => SizedBox(
                                width: (MediaQuery.sizeOf(context).width - 30) / 2,
                                child: RadioListTile<DmsLetterRequestType>(
                                  value: item,
                                  groupValue: _requestType,
                                  onChanged: formIsLoading ? null : (value) => setState(() {
                                    _requestType = value;
                                    _requestTypeError = false;
                                  }),
                                  title: Text(item.name),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),

                      Divider(),

                      // тип связи
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Выберите тип обратной связи', style: TextStyle(
                              color: !_contactTypeError ? null : Theme.of(context).colorScheme.error,
                            )),
                            SizedBox(height: 5),
                            Wrap(
                              children: _contactTypes.map((item) => SizedBox(
                                width: (MediaQuery.sizeOf(context).width - 30) / 2,
                                child: RadioListTile<DmsLetterContactType>(
                                  value: item,
                                  groupValue: _contactType,
                                  onChanged: formIsLoading ? null : (DmsLetterContactType? value) async {
                                    setState(() {
                                      if (_contactTypeExtraBlockIsClosing) {
                                        _contactTypeExtraBlockIsClosing = false;
                                      }
                                      _contactType = value;
                                      _contactTypeError = false;
                                    });

                                    // отображаем доп. блок
                                    final bool toToggle = value != null && {
                                      '01', // звонок
                                      '03', // смс
                                      '04', // email
                                    }.contains(value.code);
                                    _toggleContactTypeExtraBlockVisibility(toToggle);
                                    if (toToggle) {
                                      setState(() {
                                        switch(value.code) {
                                          case '01': // звонок
                                            _contactTypeExtraBlockLabels = [
                                              'Использовать мой телефон',
                                              'Указать другой телефон',
                                            ];
                                            _otherContactController.text = _contactTypeNotMyself
                                                ? '' : _defaultContactPhone;
                                            break;
                                          case '03': // смс
                                            _contactTypeExtraBlockLabels = [
                                              'Использовать мой телефон',
                                              'Указать другой телефон',
                                            ];
                                            _otherContactController.text = _contactTypeNotMyself
                                                ? '' : _defaultContactPhone;
                                            break;
                                          case '04': // email
                                            _contactTypeExtraBlockLabels = [
                                              'Отправить на мой Email',
                                              'Отправить на другой Email',
                                            ];
                                            _otherContactController.text = _contactTypeNotMyself
                                                ? '' : _defaultContactEmail;
                                            break;
                                        }
                                      });
                                    } else {
                                      setState(() => _contactTypeExtraBlockIsClosing = true);
                                      await Future.delayed(const Duration(milliseconds: 600));
                                      if (_contactTypeExtraBlockIsClosing) {
                                        setState(() {
                                          _contactTypeExtraBlockLabels = ['', ''];
                                          _contactTypeExtraBlockIsClosing = false;
                                        });
                                      }
                                    }
                                  },
                                  title: Text(item.name),
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),

                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            axisAlignment: -1,
                            child: Opacity(
                              opacity: animation.value,
                              child: Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE5E5EA),
                                  borderRadius: BorderRadius.all(Radius.circular(10))
                                ),
                                child: Wrap(
                                  children: [
                                    SizedBox(
                                      width: (MediaQuery.sizeOf(context).width - 30) / 2,
                                      child: RadioListTile<bool>(
                                        value: false,
                                        groupValue: _contactTypeNotMyself,
                                        onChanged: formIsLoading ? null : (value) => setState(() {
                                          _contactTypeNotMyself = false;
                                          if (_contactType != null) {
                                            switch(_contactType!.code) {
                                              case '01': // звонок
                                              case '03': // смс
                                                _otherContactController.text = _defaultContactPhone;
                                                break;
                                              case '04': // email
                                                _otherContactController.text = _defaultContactEmail;
                                                break;
                                            }
                                          } else {
                                            // не должно быть такого
                                            _otherContactController.text = '';
                                          }
                                        }),
                                        title: Text(_contactTypeExtraBlockLabels[0]),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    SizedBox(
                                      width: (MediaQuery.sizeOf(context).width - 30) / 2,
                                      child: RadioListTile<bool>(
                                        value: true,
                                        groupValue: _contactTypeNotMyself,
                                        onChanged: formIsLoading ? null : (value) => setState(() {
                                          _contactTypeNotMyself = true;
                                          _otherContactController.text = '';
                                        }),
                                        title: Text(_contactTypeExtraBlockLabels[1]),
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.fromLTRB(12, 5, 12, 6),
                                      child: TextFormField(
                                        controller: _otherContactController,
                                        enabled: !formIsLoading,
                                        readOnly: !_contactTypeNotMyself,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        inputFormatters: _contactType?.code == '04'
                                            ? [EmailInputFormatter()]
                                            : [phoneInputFormatter],
                                        keyboardType: _contactType?.code == '04'
                                            ? TextInputType.emailAddress
                                            : TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: _contactTypeNotMyself ? Colors.white : Color(0xFFD8D8DF),
                                          prefixText: _contactType?.code == '04'
                                              ? null
                                              : '+7',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(5),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          // не требуется
                                          if (_contactType?.code == '02') {
                                            return null;
                                          }
                                          final bool isEmail = _contactType?.code == '04';
                                          if (value == '—') {
                                            return '${isEmail ? 'Email' : 'телефон'} не определён';
                                          }
                                          if (value == null || value.isEmpty) {
                                            return 'Введите ${isEmail ? 'Email' : 'телефон'}';
                                          }
                                          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                            return 'Неверный формат Email';
                                          }
                                          if (!isEmail && value.length < 16) return 'Неверный формат номера';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 25),

                      TextFormField(
                        controller: _descriptionController,
                        enabled: !formIsLoading,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.comment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(borderRadiusBig)
                            )
                          ),
                          labelText: 'Опишите симптомы, жалобы',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите текст';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 22),

                      if (_selectedFiles.isNotEmpty) Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadiusBig),
                            topRight: Radius.circular(borderRadiusBig),
                          ),
                          color: primaryLightColor,
                        ),
                        child: ListView.builder(
                          itemCount: _selectedFiles.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _buildFileItem(index),
                            );
                          },
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) Divider(height: 0),

                      // файлы
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: primaryLightColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: _selectedFiles.isEmpty
                              ? BorderRadius.circular(borderRadiusBig)
                              : BorderRadius.only(
                                bottomLeft: Radius.circular(borderRadiusBig),
                                bottomRight: Radius.circular(borderRadiusBig),
                            ),
                          ),
                          maximumSize: Size.fromHeight(minimumButtonHeightBig),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: formIsLoading ? null : _pickFiles,
                        icon: const Icon(Icons.add),
                        label: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Добавить файлы', style: TextStyle(
                              height: 1.2,
                            )),
                            Text('Максимум 10 файлов', style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                              height: 1.2,
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        icon: formIsLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.send),
                        style: getTextButtonStyle(TextButtonStyle()),
                        onPressed: formIsLoading ? null : () async {
                          final bool formValidation =
                            dmsAppointmentFormKey.currentState!.validate();

                          if (_contactType == null) _contactTypeError = true;
                          if (_requestType == null) _requestTypeError = true;
                          if (_requestCountType == null) _requestCountTypeError = true;
                          final bool otherValidation =
                            _contactType != null &&
                            _requestType != null &&
                            _requestCountType != null;
                          if (!otherValidation) setState(() { });

                          if (formValidation && otherValidation) {
                            setState(() => formIsLoading = true);
                            try {
                              final body = {
                                'token': await Auth.token,
                                'PolisId': polisId,
                                'Time': timeController.selectedItems.map((time) => time.value).join(', '),
                                'Date': _dayController.text,
                                'Description': _descriptionController.text,
                                'LPUId': lpu?.id,
                                'DmsLetterContactTypeCode': _contactType!.code,
                                'DmsLetterRequestCountTypeCode': _requestCountType!.code,
                                'DmsLetterRequestTypeCode': _requestType!.code,
                                'Email': (_contactTypeNotMyself && _contactType!.code == '04') ? _otherContactController.text : null,
                                'Phone': (_contactTypeNotMyself && _contactType!.code == '01' || _contactType!.code == '03') ? _otherContactController.text : null,
                                'Files': _selectedFiles.isEmpty ? [] : _selectedFiles.map((file) {
                                  final fileName = path.basename(file.path);
                                  final fileData = base64Encode(file.readAsBytesSync());
                                  return {
                                    'FileName': fileName,
                                    'FileData': fileData,
                                  };
                                }).toList(),
                              };

                              final response = await Http.mobApp(ApiParams('MobApp', 'MP_dms_doctor_req', body));
                              if (context.mounted) {
                                if (response['Error'] == 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(response['Message'] ?? 'Ошибка')),
                                  );
                                  setState(() => formIsLoading = false);
                                }
                                else if (response['Error'] == 1) {
                                  Auth.logout(context, true);
                                }
                                else if (response['Error'] == 0) {
                                  context.go('/dms/history');
                                }
                              }
                            } catch (e) {
                              print(e);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка'))
                                );
                              }
                              await Future.delayed(const Duration(seconds: 2));
                              setState(() => formIsLoading = false);
                            }

                          }
                        },
                        label: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: const Text('Отправить'),
                        ),
                      ),

                      SizedBox(height: 10),

                    ],
                  ),
                );

              }
            }
          },
        )
      )
    );
  }

  Future<DateTime?> _openDayTimePicker(BuildContext context) async {
    DateTime? initialDate = _dayController.text != ''
        ? DateFormat('dd.MM.yyyy').tryParse(_dayController.text)
        : null;
    DateTime firstDate = DateTime.now();
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));
    if (
      initialDate != null && initialDate.isAfter(lastDate) ||
      initialDate != null && initialDate.isBefore(firstDate)
    ) {
      initialDate = null;
    }
    return await showDatePicker(
      locale: const Locale('ru', 'ru_Ru'),
      context: context,
      fieldHintText: 'DATE/MONTH/YEAR',
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
  }

  void _selectLPU(BuildContext context, String polisId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DmsLpuList(
          policyId: polisId,
          returnLPU: _setLPU,
        ),
      ),
    );
  }

  void _setLPU(DmsLpu selectedLpu) {
    setState(() {
      lpu = selectedLpu;
      _lpuController.text = '${selectedLpu.name}\n\n${selectedLpu.address}';
    });
  }

}
