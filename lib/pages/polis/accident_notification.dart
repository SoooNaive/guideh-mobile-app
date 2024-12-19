import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/services/camera.dart';
import 'package:guideh/services/format_time.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AccidentNotificationPage extends StatefulWidget {
  final Policy policy;
  const AccidentNotificationPage({super.key, required this.policy});

  @override
  State<AccidentNotificationPage> createState() => _AccidentNotificationPageState();
}

class _AccidentNotificationPageState extends State<AccidentNotificationPage> {

  bool isLoading = false;
  bool isLoaded = false;

  final accidentNotificationFormKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(DateTime.now()));
  final TextEditingController _timeController = TextEditingController(text: DateFormat('Hm').format(DateTime.now()));
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final RegExp timeRexExp = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');

  final List<String> imagePathes = [];

  void addPhoto(String imagePath) {
    setState(() {
      imagePathes.add(imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомление о ДТП'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text('Полис № ${widget.policy.docNumber}'),
              subtitle: Text(widget.policy.objectName),
            ),
            const Divider(height: 5),
            const SizedBox(height: 10),
            isLoading
              ? isLoaded
                ? const SizedBox.shrink()
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 55),
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text('Загрузка'),
                    ],
              )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: accidentNotificationFormKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.date_range),
                            border: UnderlineInputBorder(),
                            labelText: 'Дата ДТП',
                          ),
                          onTap: () async {
                            final DateTime? selected = await showDatePicker(
                              locale: const Locale('ru', 'ru_Ru'),
                              context: context,
                              fieldHintText: 'DATE/MONTH/YEAR',
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (selected != null) {
                              setState(() {
                                _dateController.text = DateFormat('dd.MM.yyyy').format(selected);
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите дату ДТП';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.access_time_filled),
                            border: UnderlineInputBorder(),
                            labelText: 'Время ДТП',
                            counterText: '',
                          ),
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          inputFormatters: [TimeTextFormatter()],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите время ДТП';
                            }
                            else if (value.length != 5 || !timeRexExp.hasMatch(value) || int.parse(value.split(':')[0]) > 23 || int.parse(value.split(':')[1]) > 59 ) {
                              return 'Неверный формат времени';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.pin_drop),
                            border: UnderlineInputBorder(),
                            labelText: 'Адрес места ДТП',
                          ),
                          minLines: 1,
                          maxLines: 3,
                          keyboardType: TextInputType.streetAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите адрес';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _commentController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.comment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(borderRadiusBig)
                              )
                            ),
                            labelText: 'Обстоятельства страхового случая',
                          ),
                          keyboardType: TextInputType.multiline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите текст';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Добавить фото'),
                            style: getTextButtonStyle(
                              TextButtonStyle(theme: 'primaryLight'),
                            ),
                            onPressed: () async {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => TakePhoto(addPhoto: addPhoto),
                              ));
                            },
                          ),
                        ),
                        const SizedBox(height: 5),

                        imagePathes.isNotEmpty
                          ? Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xffe2e2e2),
                              borderRadius: BorderRadius.all(
                                Radius.circular(borderRadiusBig)
                              ),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: List.generate(imagePathes.length, (index) {
                                return SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: FittedBox(
                                    clipBehavior: Clip.hardEdge,
                                    fit: BoxFit.cover,
                                    child: Image.file(File(imagePathes[index])),
                                  ),
                                );
                              }),
                            ),
                          )
                          : const SizedBox.shrink(),

                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Отправить'),
                                style: getTextButtonStyle(),
                                onPressed: () async {
                                  if (accidentNotificationFormKey.currentState!.validate()) {

                                    setState(() {
                                      isLoading = true;
                                    });

                                    final preferences = await SharedPreferences.getInstance();
                                    final body = {
                                      'UserToken': preferences.getString('token'),
                                      'UserPhone': preferences.getString('phone'),
                                      'DocId': '',
                                      'DocNumber': widget.policy.docNumber,
                                      'AccidentTime': _timeController.text,
                                      'AccidentDate': _dateController.text,
                                      'AccidentPlace': _addressController.text,
                                      'Description': _commentController.text,
                                      'Files': imagePathes.map((imagePath) => {
                                        'FileData': base64Encode(File(imagePath).readAsBytesSync()),
                                        'FileName': 'accident_notification_${widget.policy.docNumber}_${DateFormat('yMd_Hms').format(DateTime.now())}.jpg',
                                      }).toList(),
                                    };

                                    final response = await Http.mobApp(
                                      ApiParams('Notification', 'MP_Not_Save', body)
                                    );

                                    if (response['Error'] == 2) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(response['Message'] ?? 'Ошибка'),
                                          ),
                                        );
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                    else if (response['Error'] == 1) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(body.toString()),
                                          ),
                                        );
                                      }
                                    }
                                    else if (response['Error'] == 0) {
                                      if (context.mounted) {
                                        setState(() {
                                          isLoaded = true;
                                        });
                                        return showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) =>
                                            AlertDialog(
                                              title: const Text('Отправлено'),
                                              content: const Text(
                                                'Уведомление о ДТП успешно отправлено.',
                                                textAlign: TextAlign.center
                                              ),
                                              icon: const Icon(Icons.done),
                                              actionsAlignment: MainAxisAlignment.spaceBetween,
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Icon(Icons.arrow_back_sharp),
                                                      SizedBox(width: 4),
                                                      Text('К полису'),
                                                    ],
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => context.go('/sos'),
                                                  child: const Text('Список уведомлений'),
                                                ),
                                              ],
                                            ),
                                        );
                                      }
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Ошибка'),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
