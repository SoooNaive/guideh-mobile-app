import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// запрос в GAI API

Future<Map<String, dynamic>?> gaiApiRequest(
  String url, [
    Map<String, dynamic>? body,
    BuildContext? context
  ]) async {

  SharedPreferences preferences = await SharedPreferences.getInstance();

  final bool isTokenRequest = url == '/login/';
  String? token;

  print(('---> https://client.guideh.com/api/gai$url'));
  http.Request request = http.Request(
      body != null ? 'POST' : 'GET',
      Uri.parse('https://client.guideh.com/api/gai$url')
  );

  // add bearer token
  if (!isTokenRequest) {
    token = preferences.getString('gaiAccessToken');
    token ??= await updateAccessToken();
    request.headers.addAll({ 'Authorization': 'Bearer $token' });
  }

  // добавим agentId
  String? agentId = preferences.getString('agentId');
  if (body != null && agentId != null) {
    body['agentId'] = agentId;
  }

  print('body: $body');

  if (body != null) request.body = json.encode(body);

  request.headers.addAll({ 'Content-Type': 'application/json' });

  http.StreamedResponse response;
  try {
    response = await request.send();
  } catch (e) {
    print('ошибка при запросе в gaiApiRequest');
    print(e);
    return null;
  }

  print(response.statusCode);

  // update token
  if (response.statusCode == 401) {
    token = isTokenRequest ? null : await updateAccessToken();
  }

  // check if finally got token
  if (!isTokenRequest && token == null) {
    print('Ошибка получения accessToken');
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 6),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          content: Text('Ошибка получения токена авторизации'),
        ),
      );
    } else {
      print('Нет контекста для снекбара');
    }
    // exit
    return null;
  }

  // update token in headers
  if (!isTokenRequest && response.statusCode == 401) {
    request.headers.addAll({ 'Authorization': 'Bearer $token' });
    // send request again with new token
    response = await request.send();
    print('отправили запрос с новым токеном');
    print(response.statusCode);
  }

  final responseString = await response.stream.bytesToString();
  Map<String, dynamic> decodedJSON;
  try {
    decodedJSON = json.decode(responseString);
  } on FormatException catch (e) {
    print('! Ответ GAI API ($url) не является объектом JSON: ${e.message}');
    print(responseString);
    return null;
  }
  if (!isTokenRequest && !decodedJSON['error'].isEmpty) {
    print(decodedJSON['error'][0]);
    return decodedJSON;
  }
  return decodedJSON;
}

// обновляем токен
Future<String?> updateAccessToken() async {
  print('go updateAccessToken!');
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.remove('gaiAccessToken');
  final response = await gaiApiRequest('/login/', {
    'login': 'MobApp',
    'password': 'qhRQL74##6',
    // 'login': 'TestAPI',
    // 'password': 'TestAPI',
  });
  print(response);
  final String? token = await response?['accessToken'];
  print('updated token: $token');
  if (token != null) {
    preferences.setString('gaiAccessToken', token);
  }
  return token;
}