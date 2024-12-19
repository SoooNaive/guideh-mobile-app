import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;


class Auth {

  static Future<String> get token async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? '';
    return token;
  }

  static Future<bool> checkAuth([BuildContext? context]) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token') ?? '';
    if (token.isEmpty) {
      return false;
    }
    final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_check_token', {
        'token': token,
        'os': Platform.operatingSystem,
      })
    );
    if (response['Error'] != 0) {
      if (context != null && context.mounted) {
        logout(context);
      }
      return false;
    }
    // todo: update
    // preferences.setString('guideh_actual_app_version', response['ActualAppVersion']);
    return true;
  }

  static Future<dynamic> login(String phone, String password, BuildContext context) async {
    final body = {
      'phone': phone,
      'password': password,
      'ip': '656565',
      'UpdateListPolis': false,
    };
    final response = await Http.mobApp(ApiParams('MobApp', 'MP_login', body));

    print(response);

    if (response['Error'] == 0) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString('phone', phone);
      preferences.setString('password', password);
      preferences.setString('userName', response['Name']);
      preferences.setString('token', response['token']);
      preferences.setString('DMSPhone', response['DMSPhone']);
      preferences.setString('DMSEmail', response['DMSEmail']);
      if (response['AgentId'] != null) {
        preferences.setString('agentId', response['AgentId']);
      }

      // если в shared prefs есть deeplink → перенаправляем
      // дублировать этот функционал в main.dart
      final String? link = preferences.getString('deepLink');
      if (link != null && context.mounted) {
        final parsedLink = Uri.parse(link);
        // осмотр загородного дома
        if (parsedLink.queryParameters.containsKey('house_checkup')) {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          await preferences.remove('deeplink');
          if (context.mounted) {
            context.goNamed('checkup_house_start', extra: parsedLink.queryParameters);
          }
          return;
        }
        // осмотр КАСКО
        if (parsedLink.queryParameters.containsKey('kasko_checkup')) {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          await preferences.remove('deeplink');
          if (context.mounted) {
            context.goNamed('checkup_kasko_start', extra: parsedLink.queryParameters);
          }
          return;
        }
      }

      return 'OK';
    } else {
      return response['Message'];
    }
  }

  static void logout(BuildContext context, [bool reloginRequired = false]) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove('userName');
    preferences.remove('token');
    preferences.remove('gaiAccessToken');
    preferences.remove('agentId');
    // todo: update
    // preferences.remove('guideh_actual_app_version');
    if (context.mounted) {
      if (reloginRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Время сеанса вышло, войдите заново'),
          ),
        );
        context.go('/start/login');
      }
      else {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Navigator does not exist, handle the error
        }
        context.go('/start');
      }
    }
  }

  static Future<dynamic> passRecovery(String phone) async {
    final body = {'phone': phone};
    final response = await Http.mobApp(ApiParams('MobApp', 'MP_pass_rec', body));

    if (response['Error'] == 0) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString('phone', phone);
      return 'OK';
    } else {
      return response['Message'];
    }
  }

}
