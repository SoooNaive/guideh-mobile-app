import 'dart:async';
import 'dart:convert';
import 'package:guideh/services/auth.dart';
import 'package:http/http.dart' as http;

class ApiParams {
  String service;
  String method;
  Object? body = '';

  ApiParams(
    this.service,
    this.method,
    [this.body]
  );
}

class Http {

  static Future mobApp(ApiParams params) async {
    print('----> token: ${await Auth.token} | ${params.service}/${params.method}');

    final request = http.Request('POST', Uri.parse('https://client.guideh.com/api/MobApp.php'));
    request.body = json.encode(params.body);
    request.headers.addAll({
      'Authorization': 'Basic TW9iQXBwOnFoUlFMNzQjIzY=',
      'Content-Type': 'application/json',
      'Service': params.service,
      'Method': params.method,
    });
    try {
      http.StreamedResponse response = await request
        .send()
        .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();
        // парсим json
        Map<String, dynamic> decodedJSON;
        try {
          decodedJSON = json.decode(responseString) as Map<String, dynamic>;
        } on FormatException catch (e) {
          // ! ошибка при парсинге JSON
          print('! Ответ не JSON: ${e.message} :');
          print(responseString);
          decodedJSON = jsonDecode('{"Error": 3, "Message": "Ошибка запроса, попробуйте позже"}');
        }
        // ответ
        return decodedJSON;
      } else {
        // ! ошибка при ожидании потока респонса
        return jsonDecode('{"Error": 3, "Message": "Ошибка запроса, попробуйте позже."}');
      }

    } catch (e) {
      // ! ошибка при отправке запроса
      print(e);
      return jsonDecode('{"Error": 3, "Message": "Ошибка. Попробуйте ещё раз или проверьте подключение к интернету."}');
    }

  }

}
