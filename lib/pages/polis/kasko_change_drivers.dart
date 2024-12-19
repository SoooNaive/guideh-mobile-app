import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/my_title.dart';
import 'package:guideh/pages/polis/kasko_change_drivers_add.dart';
import 'package:guideh/pages/polis/models/kasko_driver.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class KaskoChangeDriversPage extends StatefulWidget {
  final Policy policy;
  const KaskoChangeDriversPage({super.key, required this.policy});

  @override
  State<KaskoChangeDriversPage> createState() => _KaskoChangeDriversPageState();
}

class _KaskoChangeDriversPageState extends State<KaskoChangeDriversPage> {

  bool isSubmitting = false;
  bool hasChanges = false;

  late List<KaskoDriver>? _drivers;
  List<KaskoDriver> driversAdded = [];
  List<KaskoDriver> driversMarkedToDelete = [];
  late Future<void>? _initDataLoad;

  Future<void> _initData() async {
    _drivers = await _loadDrivers();
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Изменить водителей'),
      ),
      body: FutureBuilder(
        future: _initDataLoad,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              {
                return const Center(child: CircularProgressIndicator());
              }
            case ConnectionState.done:
              _drivers = _drivers ?? [];
              {
                return isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MyTitle('Полис ${policy.type} №${policy.docNumber}'),

                        // удалить водителей

                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: ListTile.divideTiles(
                            context: context,
                            tiles: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                                child: Text(
                                  'Удалить водителей:',
                                  style: TextStyle(fontWeight: FontWeight.bold)
                                ),
                              ),
                              ..._drivers!.map((driver) {
                                final bool markedToDelete = driversMarkedToDelete.contains(driver);
                                return Container(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8
                                  ),
                                  color: markedToDelete ? const Color(0x15ff0000) : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                markedToDelete ? Icons.person_off : Icons.person,
                                                color: markedToDelete ? Colors.red : Colors.black26,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(
                                                driver.name,
                                                style: TextStyle(
                                                  color: markedToDelete ? Colors.red : Colors.black
                                                ),
                                              )),
                                            ],
                                          )
                                      ),
                                      const SizedBox(width: 8),
                                      markedToDelete
                                        ? Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                                            border: Border.all(
                                              color: const Color(0x25FF0000),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 5
                                          ),
                                          child: const Text(
                                            'Будет удалён',
                                            style: TextStyle(
                                              color: Color(0xFFDD0000),
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                        : TextButton(
                                          style: TextButton.styleFrom(
                                            // backgroundColor: const Color(0x18ff0000),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(7),
                                            ),
                                            side: const BorderSide(color: Color(0xBBFF6767)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5,
                                                horizontal: 8
                                            ),
                                            alignment: Alignment.center,
                                            foregroundColor: const Color(0xFFFF6767),
                                            textStyle: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) {
                                                return AlertDialog(
                                                  title: const Text('Подтвердите удаление'),
                                                  content: SingleChildScrollView(
                                                    child: Text('Удалить водителя ${driver.name} из полиса?'),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      child: const Text('Отмена'),
                                                      onPressed: () => dialogContext.pop(false),
                                                    ),
                                                    TextButton(
                                                      child: const Text('Удалить'),
                                                      onPressed: () {
                                                        dialogContext.pop(false);
                                                        _deleteDriver(driver);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.person_remove, color: Colors.red),
                                              Text('Удалить'),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox.shrink(),
                            ],
                          ).toList(),
                        ),

                        // добавить водителей

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Добавить водителей:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  side: const BorderSide(color: Color(0xBB00BB00)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 8
                                  ),
                                  alignment: Alignment.center,
                                  foregroundColor: const Color(0xFF00BB00),
                                  textStyle: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => KaskoChangeDriversAddPage(
                                      addedDriver: _addDriver,
                                    ),
                                  ),
                                ),
                                // onPressed: _showAddDriverDialog,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_add_alt_1, color: Color(0xFF00BB00)),
                                    Text('Добавить'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (driversAdded.isNotEmpty) ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),

                          children: ListTile.divideTiles(
                            context: context,
                            tiles: [
                              const SizedBox(height: 1),
                              ...driversAdded.map(
                                (driverAdded) => Container(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8
                                  ),
                                  color: const Color(0x2533CC33),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person_add_alt_1,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(
                                                    driverAdded.name,
                                                    style: const TextStyle(color: Color(0xFF00AA00)),
                                                  )
                                              ),
                                            ],
                                          )
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                                          border: Border.all(
                                            color: const Color(0x30008800),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 5
                                        ),
                                        child: const Text(
                                          'Будет добавлен',
                                          style: TextStyle(
                                            color: Color(0xFF008800),
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ),
                              const SizedBox.shrink(),
                            ],
                          ).toList(),
                        ),

                        if (hasChanges) Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: TextButton.icon(
                              icon: const Icon(Icons.send),
                              label: const Text('Сохранить все изменения'),
                              style: getTextButtonStyle(),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Сохранить изменения'),
                                    content: const SingleChildScrollView(
                                      child: Text('Отправить изменения на проверку?'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => dialogContext.pop(),
                                        child: const Text('Отмена'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          dialogContext.pop();
                                          setState(() {
                                            isSubmitting = true;
                                          });
                                          _submit();
                                        },
                                        child: const Text('Отправить')
                                      ),
                                    ],
                                  );
                                },
                              )
                          ),
                        ),
                      ],
                    ),
                  );
              }
          }
        }
      ),
    );
  }

  Future<List<KaskoDriver>> _loadDrivers() async {
    print(widget.policy.docId);
    final response = await Http.mobApp(
      ApiParams('GD_Service', 'MobApp_PolisData', { 'DocId': widget.policy.docId })
    );
    List<KaskoDriver> drivers = [];
    for (var driver in response['Insureds']) {
      drivers.add(KaskoDriver.fromJson(driver));
    }
    return drivers;
  }

  _deleteDriver(KaskoDriver driverToDelete) {
    setState(() {
      driversMarkedToDelete.add(driverToDelete);
      hasChanges = true;
    });
  }

  _submit() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    String description = 'Полис КАСКО № ${widget.policy.docNumber}:';
    if (driversMarkedToDelete.isNotEmpty) {
      description += '\n\nУдалить водителей:';
      for(var driver in driversMarkedToDelete) {
        description += '\n- ${driver.name} | ${driver.birthdate} | ВУ № ${driver.docSeries} ${driver.docNumber}';
      }
    }
    if (driversAdded.isNotEmpty) {
      description += '\n\nДобавить водителей:';
      for(var driverAdded in driversAdded) {
        description += '\n- ${driverAdded.name} | ${driverAdded.birthdate} | ВУ № ${driverAdded.docSeries} ${driverAdded.docNumber}';
      }
    }

    List<String> photoPathes = [];
    if (driversAdded.isNotEmpty) {
      for(var driverAdded in driversAdded) {
        if (driverAdded.docPhotoPaths != null && driverAdded.docPhotoPaths!.isNotEmpty) {
          for(var photoPath in driverAdded.docPhotoPaths!) {
            photoPathes.add(photoPath);
          }
        }
      }
    }

    final response = await Http.mobApp(
      ApiParams('ClientsRequest', 'Req_save_b2b', {
        'Resource': 'Мобильное приложение',
        'Theme': 'КАСКО – Дополнительное соглашение',
        'Name': preferences.getString('userName') ?? '',
        'Phone': preferences.getString('phone') ?? '',
        'Email': '',
        'IP': '',
        'Description': description,
      })
    );

    if (response['Status'] != 'ok') {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ошибка отправки заявки. Попробуйте позже, либо воспользуйтесь формой "Обращение" в Личном кабинете.'
            ),
          ),
        );
      }
      return;
    }
    else {

      if (photoPathes.isNotEmpty) {
        for(var photoPath in photoPathes) {
          await Http.mobApp(
            ApiParams('ClientsRequest', 'Scan_save', {
              'ID': response['DocId'],
              'FileName': 'kasko_add_driver_${widget.policy.docNumber}_${DateFormat('yMd_Hms').format(DateTime.now())}.jpg',
              'prefix': 'data:image/jpeg;base64',
              'FileData': base64Encode(File(photoPath).readAsBytesSync()),
              'FileType': '01',
            })
          );
        }
      }

      if (mounted) {
        return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Успешно'),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              content: const Text('Ваша заявка на изменение данных по водителям отправлена. С Вами свяжется оператор колл-центра.'),
              actions: [
                TextButton(
                  child: const Text('Хорошо'),
                  onPressed: () {
                    dialogContext.pop();
                    context.pop();
                    context.pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  _addDriver(KaskoDriver driver) {
    driversAdded.add(driver);
    hasChanges = true;
    setState(() {});
  }

}
