import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guideh/layout/scaffold/scaffold_bloc.dart';
import 'package:guideh/pages/about_app/about_app.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => DrawerMenuState();
}

class DrawerMenuState extends State<DrawerMenu> {
  String userName = '';
  // todo: update
  // bool updateAppFailed = false;

  late bool pushesJustGranted;

  void getUserName() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      userName = (preferences.getString('userName') ?? '');
    });
  }

  @override
  void initState() {
    super.initState();
    getUserName();
    pushesJustGranted = false;
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBloc = BlocProvider.of<ScaffoldBloc>(context);
    final bool pushesIsGranted =
        scaffoldBloc.state.notificationsPermissionStatus == PermissionStatus.granted;
    return Drawer(
      child: Column(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Container(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [

                // GestureDetector(
                //   child: const ListTile(
                //     leading: Icon(Icons.account_circle),
                //     title: Text('Профиль'),
                //   ),
                //   onTap: () {
                //     Navigator.of(context).pop();
                //     context.go('/profile');
                //   }
                // ),
                // const Divider(height: 1),

                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Выйти'),
                  ),
                  onTap: () => _logoutDialog(context)
                ),
                const Divider(height: 1),

              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pushesJustGranted || !pushesIsGranted) Column(
                children: [
                  const Divider(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(15, 20, 5, 20),
                          child: Text(
                            'Присылать push-уведомления уведомления',
                            maxLines: 2,
                            style: TextStyle(color: Color(0xff666666)),
                          ),
                        ),
                      ),
                      Switch(
                        value: pushesIsGranted || pushesJustGranted,
                        onChanged: (bool enable) async {
                          if (enable) {
                            await requestNotificationPermission(scaffoldBloc);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 1),
              GestureDetector(
                child: const ListTile(
                  title: Text(
                    'Перейти на сайт АО ГАЙДЕ',
                    style: TextStyle(
                      color: Colors.transparent,
                      decorationColor: Colors.grey,
                      shadows: [Shadow(color: Color(0xff666666), offset: Offset(0, -3))],
                      decoration: TextDecoration.underline,
                      decorationThickness: 1,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(Icons.open_in_new, size: 22),
                ),
                onTap: () => goUrl('https://guidehins.ru/'),
              ),
              const Divider(height: 1),
              GestureDetector(
                child: const ListTile(
                  title: Text(
                    'Информация для потребителей финансовых услуг',
                    style: TextStyle(
                      color: Colors.transparent,
                      decorationColor: Colors.grey,
                      shadows: [Shadow(color: Color(0xff666666), offset: Offset(0, -3))],
                      decoration: TextDecoration.underline,
                      decorationThickness: 1,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(Icons.open_in_new, size: 22),
                ),
                onTap: () => goUrl(informationOfFinancialServicesUrl),
              ),
              const Divider(height: 1),
              GestureDetector(
                child: const ListTile(
                  title: Text(
                    'О приложении',
                    style: TextStyle(
                      color: Colors.transparent,
                      decorationColor: Colors.grey,
                      shadows: [Shadow(color: Color(0xff666666), offset: Offset(0, -3))],
                      decoration: TextDecoration.underline,
                      decorationThickness: 1,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppPage())
                  );
                },
              ),
              // todo: update
              // GestureDetector(
              //   child: ListTile(
              //     tileColor: const Color.fromRGBO(140, 185, 40, 1),
              //     title: updateAppFailed
              //       ? const Text('Не удалось открыть ссылку. Пожалуйста, обновите приложение из магазина приложений.',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontWeight: FontWeight.normal
              //         ),
              //       )
              //       : Text('Обновить приложение'.toUpperCase(),
              //         style: const TextStyle(
              //           color: Colors.white,
              //         ),
              //       ),
              //     leading: updateAppFailed
              //       ? null
              //       : const Icon(Icons.system_update_tv_rounded, color: Colors.white),
              //   ),
              //   onTap: () async {
              //     if (updateAppFailed) return;
              //     final url = Uri.parse(
              //       Platform.isAndroid
              //         ? 'market://details?id=com.guideh.guideh'
              //         : 'https://apps.apple.com/ru/app/id6446365343',
              //     );
              //     if (await canLaunchUrl(url)) {
              //       launchUrl(url, mode: LaunchMode.externalApplication);
              //     }
              //     else {
              //       setState(() => updateAppFailed = true);
              //     }
              //   },
              // ),
              if (Platform.isIOS) const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> requestNotificationPermission(ScaffoldBloc scaffoldBloc) async {
    final PermissionStatus status = await Permission.notification.request();
    scaffoldBloc.add(ScaffoldUpdateNotificationsPermissionStatusEvent(status));
    if (status.isGranted) {
      setState(() {
        pushesJustGranted = true;
      });
    } else if (status.isDenied) {
      // попробовать запросить разрешение снова
      requestNotificationPermission(scaffoldBloc);
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Уведомления отключены'),
            content: const Text('Уведомления постоянно отклонены. Для включения уведомлений, пожалуйста, предоставьте разрешение в настройках телефона.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

}

Future<void> _logoutDialog(context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // title: const Text('AlertDialog Title'),
        content: const SingleChildScrollView(
          child: Text('Вы уверены, что хотите выйти из профиля?'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Выйти'),
            onPressed: () => Auth.logout(context),
          ),
          TextButton(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

