// общие функции и константы

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

String appVersion = '1.2.6';

// телефон по умолчанию
String globalPhoneNumber = '8-800-444-02-75';
String dmsSosPhoneNumber = '8-800-555-15-70';
// todo
String ambulancePhoneNumber = '8-800-555-15-70,1';

// ссылки на политики
String privacyPolicyUrl = 'https://guidehins.ru/privacy-policy/';
String userAgreementUrl = 'https://guidehins.ru/politika-v-otnoshenii-obrabotki-personalnyx-dannyx/';
String informationOfFinancialServicesUrl = 'https://guidehins.ru/informaciya-dlya-potrebitelej-finansovyx-uslug/';

String esiaLoginUrl = 'https://client.guidehins.ru/esiagost/?from_mobile_app=true';

// позвонить
Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
}

// написать email
Future<void> goEmail(String email) async {
  final Uri launchUri = Uri(
    scheme: 'mailto',
    path: email,
  );
  await launchUrl(launchUri);
}

// перейти по url
Future<void> goUrl(String url, {LaunchMode mode = LaunchMode.platformDefault}) async {
  final uri = Uri.parse(url);
  final launch = await launchUrl(uri, mode: mode);
  // if (await canLaunchUrl(uri)) {
  if (!launch) {
    throw Exception('Не удалось перейти по ссылке');
  }
  return;
}

// удаляем из строки html-теги, только <br> меняем на переносы строк
String parseHtmlString(String htmlString) {
  RegExp expBr = RegExp(
      r"<br\s*/?>",
      multiLine: true,
      caseSensitive: true
  );
  RegExp exp = RegExp(
      r"<[^>]*>",
      multiLine: true,
      caseSensitive: true
  );
  return htmlString.replaceAll(expBr, '\n').replaceAll(exp, '');
}

// координаты центров городов и зум
List<double> getPointOfCity(String cityId) {
  List<double> coords;
  double zoom = 11;
  switch (cityId) {
  // Санкт-Петербург
    case '1': coords = [30.315635, 59.938951]; zoom = 11; break;
  // Архангельск
    case '32': coords = [40.541247, 64.544414]; zoom = 12; break;
  // Великий Новгород
    case '4': coords = [58.522857, 31.269816]; zoom = 12; break;
  // Верхняя Салда
    case '16': coords = [58.050898, 60.546253]; zoom = 12; break;
  // Грозный
    case '7': coords = [43.318366, 45.692421]; zoom = 12; break;
  // Екатеринбург
    case '14': coords = [56.838011, 60.597474]; zoom = 12; break;
  // Ижевск
    case '6': coords = [56.845081, 53.188062]; zoom = 12; break;
  // Калининград
    case '5': coords = [54.710162, 20.510137]; zoom = 12; break;
  // Краснодар
    case '12': coords = [45.035470, 38.975313]; zoom = 12; break;
  // Ленинградская область
    case '3': coords = [30.766278, 59.918833]; zoom = 9; break;
  // Москва
    case '2': coords = [55.755864, 37.617698]; zoom = 10; break;
  // Мурманск
    case '37': coords = [68.964319, 33.048633]; zoom = 12; break;
  // Набережные Челны
    case '9': coords = [55.703266, 52.312834]; zoom = 12; break;
  // Нижний Тагил
    case '10': coords = [57.907562, 59.971474]; zoom = 12; break;
  // Новороссийск
    case '36': coords = [44.723771, 37.768813]; zoom = 12; break;
  // Первоуральск
    case '35': coords = [56.905819, 59.943267]; zoom = 12; break;
  // Петрозаводск
    case '18': coords = [61.791244, 34.391273]; zoom = 12; break;
  // Республика Крым
    case '33': coords = [44.948237, 34.100318]; zoom = 10; break;
  // Ростов-на-Дону
    case '34': coords = [47.222078, 39.720358]; zoom = 12; break;
  // Сочи
    case '13': coords = [43.585472, 39.723098]; zoom = 12; break;
  // Сыктывкар
    case '25': coords = [61.668797, 50.836497]; zoom = 12; break;

    default: coords = [30.315635, 59.938951]; zoom = 11; break;
  }
  return [coords[1], coords[0], zoom];
}


Future<void> exitCheckupDialog(context, [String? processName]) async {
  processName ??= 'осмотр';
  String message;
  String button;
  switch(processName) {
    case 'осмотр':
      message = 'Процесс осмотра будет прерван.';
      button = 'Продолжить осмотр';
      break;
    case 'b2b_osago_add':
      message = 'Процесс оформления полиса будет прерван.';
      button = 'Продолжить оформление';
      break;
    case 'b2b_osago_list':
    default:
      message = '';
      button = 'Остаться';
      break;
  }
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Подтвердите выход'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Вы уверены, что хотите перейти в приложение?'),
              if (message != '') Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(message),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Выйти'),
            onPressed: () => context.go('/polis_list'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(backgroundColor: secondaryLightColor),
            child: Text(button),
          ),
        ],
      );
    },
  );
}

// берём точки с координатами, находим общие границы (масштаб)
List<List<double>> getBounds(List<List<String>> coordinates) {
  double padding = 0.15;
  double minLat = double.infinity;
  double minLng = double.infinity;
  double maxLat = double.negativeInfinity;
  double maxLng = double.negativeInfinity;

  for (var coords in coordinates) {
    double lat = double.parse(coords[1]);
    double lng = double.parse(coords[0]);

    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
    if (lng < minLng) minLng = lng;
    if (lng > maxLng) maxLng = lng;
  }

  return [
    [minLng - padding, minLat - padding],
    [maxLng + padding, maxLat + padding]
  ];
}
