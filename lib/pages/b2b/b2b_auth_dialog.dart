import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guideh/services/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../services/functions.dart';


class B2BAuthDialog extends StatefulWidget {
  const B2BAuthDialog({super.key, required this.dialogContext});

  final BuildContext dialogContext;

  @override
  State<B2BAuthDialog> createState() => _B2BAuthDialogState();
}

class _B2BAuthDialogState extends State<B2BAuthDialog> {

  // слушатель лайфсайкла виджета
  late final AppLifecycleListener _listener;

  // websocket
  WebSocketChannel? wsChannel;

  Map<String, dynamic>? _approveCaseData;
  bool _isError = false;
  bool _isLoading = true;
  bool _isConfirmed = false;
  bool _isConfirming = false;

  void _getApproveCase() async {
    if (!_isLoading) setState(() => _isLoading = true);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 1));
    final response = await Http.mobApp(
        ApiParams('GD_Service', 'MobApp_Approve', {
          'Type': 'Case',
          'Phone': preferences.getString('phone') ?? '',
        })
    );
    if (mounted) {
      print(response);
      setState(() {
        _approveCaseData = response;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendApprove() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? phone = preferences.getString('phone');
    if (phone == null) {
      _confirmationError();
      return;
    }

    setState(() => _isConfirming = true);

    // сообщаем бэку, что вход подтверждаем
    final response = await Http.mobApp(
      ApiParams('GD_Service', 'MobApp_Approve', {
        'Type': 'Send',
        'Phone': preferences.getString('phone') ?? '',
        ...?_approveCaseData
      })
    );
    // если плохой ответ от бэка
    if (response?['Error'] == null || response?['Error'].isNotEmpty) {
      _confirmationError();
      return;
    }

    // websocket
    setState(() {
      wsChannel = WebSocketChannel.connect(Uri.parse('wss://lk.guideh.com/wss'));
    });
    // todo: обработать здесь ошибку, когда не работает WSS
    await wsChannel!.ready;

    // отправляем подтверждение в ws
    wsChannel!.sink.add(json.encode({
      'token': phone.replaceAll(RegExp(r'[^0-9]'), ''),
      'resource': 'app',
    }));
    // слушаем ответ
    wsChannel!.stream.listen((message) async {
      print('ответ от wss: $message');
      // todo: поменять закрытие сокета с PHP на здесь ?
      setState(() => _isConfirming = false);
      if (message == '1') {
        setState(() => _isConfirmed = true);
        await Future.delayed(const Duration(seconds: 5));
        _pop();
      } else {
        _confirmationError();
      }
      wsChannel!.sink.close(status.goingAway);
    });
  }

  void _pop() {
    Navigator.pop(widget.dialogContext);
  }

  Future<void> _confirmationError() async {
    setState(() async {
      _isConfirming = false;
      _isError = true;
      await Future.delayed(const Duration(seconds: 3));
      _isError = false;
    });
  }

  @override
  void initState() {
    _getApproveCase();
    // при возврате → обновим
    _listener = AppLifecycleListener(onResume: () async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isLoading && !_isConfirming) {
        _getApproveCase();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _listener.dispose();
    if (wsChannel != null) {
      print('! ЗАКРЫЛИ !');
      wsChannel!.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasApproveCase = (_approveCaseData?['Code'] ?? '') != '';

    final List<String>? descriptions = (_approveCaseData?['Description'] ?? '') != ''
        ? _approveCaseData!['Description'].split('#')
        : null;
    final String platform = descriptions != null && descriptions.isNotEmpty ? descriptions[0] : 'не определено';
    final String regionName = descriptions != null && descriptions.length > 1 ? descriptions[1] : 'не определено';
    final String ipAddress = descriptions != null && descriptions.length > 2 ? descriptions[2] : 'не определено';


    return AlertDialog(
      title: const Text('Авторизация в B2B'),

      content: SizedBox(
        height: 150,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: _isLoading || _isConfirming
            ? const CircularProgressIndicator()

            // ошибка
            : _isError
              ? const Text('Ошибка, попробуйте ещё раз')

              // есть запрос
              : hasApproveCase

                // подтверждено
                ? _isConfirmed
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 60),
                      SizedBox(height: 8),
                      Text(
                        'Успешно!\nПроверьте страницу авторизации.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )

                  // ожидание подтверждения
                  : SizedBox(
                    width: double.infinity,
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: const TextStyle(
                          height: 1.4,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Новый запрос авторизации:\n\n',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(text: 'Платформа: $platform\n'),
                          TextSpan(text: 'IP-адрес: $ipAddress\n'),
                          TextSpan(text: 'Местоположение: $regionName'),
                        ],
                      ),
                    ),
                  )

                // нет запроса
                : RichText(
                  text: TextSpan(
                    style: const TextStyle(height: 1.4, fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'Нет новых запросов на авторизацию. Войдите в B2B по адресу ',
                        style: TextStyle(color: Colors.black)
                      ),
                      TextSpan(
                          text: 'https://lk.guideh.com/auth/',
                          style: const TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            goUrl(
                                'https://lk.guideh.com/auth/',
                                mode: LaunchMode.externalApplication
                            );
                          }
                      ),
                    ],
                  ),
                ),
              ),
            ),

      actionsOverflowButtonSpacing: 10,
      actions: [
        Row(
          children: [

            Expanded(
              child: TextButton(
                onPressed: _pop,
                style: getTextButtonStyle(TextButtonStyle(
                  size: 1,
                  theme: 'primaryLight'
                )),
                child: const Text('Отмена'),
              ),
            ),

            const SizedBox(width: 8),

            // [обновить]
            if (!hasApproveCase) Expanded(
              child: TextButton(
                style: getTextButtonStyle(TextButtonStyle(size: 1)),
                onPressed: _isLoading ? null : _getApproveCase,
                child: const Text('Обновить'),
              ),
            ),

            // [подтвердить]
            if (hasApproveCase) Expanded(
              child: TextButton(
                style: getTextButtonStyle(TextButtonStyle(size: 1, theme: 'success')),
                onPressed: _isLoading || _isConfirming || _isConfirmed
                  ? null
                  : _sendApprove,
                child: Text(_isConfirmed ? 'Успешно' : 'Подтвердить'),
              ),
            ),

          ],
        ),
      ],
    );
  }
}
