import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DaData {

  static Widget tile(String text) => ListTile(
    title: Text(text),
    dense: true,
    visualDensity: VisualDensity.comfortable,
  );

  static Future<List<String>?> search(String query) async {
    if (query == '') return List<String>.empty();

    final request = http.Request('POST', Uri.parse('https://client.guideh.com/api/MobApp_DaData.php'));
    request.body = json.encode({ 'query': query });
    try {
      http.StreamedResponse response = await request
          .send()
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();
        // парсим json
        Map<String, dynamic> decodedJSON;
        try {
          decodedJSON = json.decode(responseString) as Map<String, dynamic>;
        } on FormatException catch (e) {
          // ! ошибка при парсинге JSON
          print('! Ответ dadata не JSON: ${e.message} :');
          print(responseString);
          return null;
        }
        // ответ
        List<String> list = <String>[];
        for (var item in decodedJSON['suggestions']) {
          list.add(item['value']);
        }
        return list;
      } else {
        print('Код ответа от дадата php не 200');
        return null;
      }

    } catch (e) {
      // ! ошибка при отправке запроса
      print(e);
      return null;
    }
  }

}
