import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:guideh/services/auth.dart';
import 'package:guideh/services/format_email.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/services/pdf_viewer.dart';
import 'package:guideh/theme/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';


// [посмотреть PDF]

Future<void> dmsShowFile(
    BuildContext context,
    String dataType,
    String dataId,
    ) async {
  final token = await Auth.token;
  if (context.mounted) {
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                apiParams: ApiParams(
                  'MobApp',
                  'MP_ExecuteDMSMethod',
                  {
                    'token': token,
                    'Method': 'MP_GetFile',
                    'DataType': dataType,
                    'DataID': dataId,
                  },
                )
            )
        )
    );
  }
}


// [скачать файл]

// todo
Future<void> dmsDownloadFile(
    BuildContext context,
    String dataType,
    String dataId,
    ) async {

  final response = await Http.mobApp(ApiParams(
    'MobApp',
    'MP_ExecuteDMSMethod',
    {
      'token': await Auth.token,
      'Method': 'MP_GetFile',
      'DataType': dataType,
      'DataID': dataId,
    },
  ));
  final String? fileName = response?['Data']?['FileName'];
  final String? fileData = response?['Data']?['FileData'];

  if ((fileName ?? '') != '' && (fileData ?? '') != '') {
    String base64string = fileData!.replaceAll('\r\n', '').trim();
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final bytes = base64Decode(base64string);
    final Directory directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Открываем файл с помощью внешнего приложения
    final result = await OpenFile.open(filePath);
    print('Результат открытия файла: ${result.message}');

  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка скачивания файла')),
      );
    }
  }
}


// [отправить себе / на другой email]

Future<void> dmsSendDataToEmail(
    BuildContext context,
    String dataType,
    String dataId,
    String polisId,
    [String? email]
    ) async {

  if (context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Отправка...')),
    );
  }

  await Future.delayed(const Duration(milliseconds: 750));

  Map <String, dynamic> requestData = {
    'token': await Auth.token,
    'Method': 'MP_SendDataToEmail',
    'DataType': dataType,
    'DataId': dataId,
    'PolisId': polisId,
  };
  if ((email ?? '') != '') {
    requestData['Email'] = email;
  }

  bool isError = false;
  final response = await Http.mobApp(ApiParams(
    'MobApp',
    'MP_ExecuteDMSMethod',
    requestData,
  ));
  try {
    if (response?['Data']?['Error'] == null || response['Data']['Error'] != '3') {
      isError = true;
    }
  } catch (e) {
    print(e);
    isError = true;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isError ? 'Ошибка отправки письма' : 'Успешно отправлено'),
        showCloseIcon: true,
      ),
    );
  }
}

// модалка для ввода email

Future<void> dmsShowModalWithEmailInput(
    BuildContext parentContext,
    String dataType,
    String dataId,
    String polisId,
    ) async {

  showDialog(
    context: parentContext,
    builder: (BuildContext context) {
      final dmsModalWithEmailFormCtrl = GlobalKey<FormState>();
      final TextEditingController emailController = TextEditingController();
      return AlertDialog(
        title: const Text('Отправить на почту'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('Введите адрес Email'),
              Form(
                key: dmsModalWithEmailFormCtrl,
                child: TextFormField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [EmailInputFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите Email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Неверный формат Email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (dmsModalWithEmailFormCtrl.currentState!.validate()) {
                dmsSendDataToEmail(
                  parentContext,
                  dataType,
                  dataId,
                  polisId,
                  emailController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      );
    },
  );
}