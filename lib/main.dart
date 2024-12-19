import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:guideh/layout/scaffold/scaffold_bloc.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/push_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

import 'package:guideh/theme/theme.dart';
import 'package:guideh/router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


void main() {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // отключим авто скрытие splash-screen, позже сами его уберём
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // инициализация пуш-уведомлений
  NotificationManager().initNotification();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final _appKey = GlobalKey();

  // app links

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();
    // Handle links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      openAppLink(uri.toString());
    });
  }

  // редирект по апп линку
  Future<void> openAppLink(String? link) async {
    if (link == null) return;
    // дублировать этот функционал в auth.dart
    final parsedLink = Uri.parse(link);
    // пускаем только https://guidehins.ru/app/...
    if (parsedLink.pathSegments[0] != 'app') return;

    // осмотр House / Kasko
    final isHouseCheckup = parsedLink.queryParameters.containsKey('house_checkup');
    final isKaskoCheckup = parsedLink.queryParameters.containsKey('kasko_checkup');
    // возврат с оплаты полиса осаго (b2b_osago_add)
    final isTinkoffReturn = parsedLink.queryParameters.containsKey('tinkoff_return');
    final bool gotDeepLink = isHouseCheckup || isKaskoCheckup || isTinkoffReturn;
    if (gotDeepLink) {
      print('got app link!');
      SharedPreferences preferences = await SharedPreferences.getInstance();
      // залогинен → перенаправляем на осмотр
      if (mounted && await Auth.checkAuth(context)) {
        await preferences.remove('deeplink');
        String? route;
        if (isHouseCheckup) {
          route = 'checkup_house_start';
        } else if (isKaskoCheckup) {
          route = 'checkup_kasko_start';
        } else if (isTinkoffReturn) {
          // успешная оплата
          if (parsedLink.queryParameters['tinkoff_return'] == '1'
            && parsedLink.queryParameters['contract_id'] != null) {
            route = 'tinkoff_return';
          }
          // не успешная
          else {
            print('deeplink от тинькова - не успешная оплата');
            return;
          }
        }
        if (route != null) {
          appRouter.goNamed(route, extra: parsedLink.queryParameters);
        } else {
          print('не удалось распознать deepLink');
        }
      }
      // не залогинен → записываем в shared prefs
      else {
        await preferences.setString('deepLink', link);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() async {
    _linkSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final scaffoldBloc = ScaffoldBloc();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => scaffoldBloc),
      ],
      child: MaterialApp.router(

        title: "ГАЙДЕ страхование",
        key: _appKey,
        theme: appTheme,
        routerConfig: appRouter,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ru', ''),
        ],
        debugShowCheckedModeBanner: false,

      ),
    );

  }
}
