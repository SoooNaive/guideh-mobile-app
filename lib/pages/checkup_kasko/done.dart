import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/functions.dart';

import 'alert.dart';

class CheckupKaskoDone extends StatelessWidget {
  const CheckupKaskoDone({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => exitCheckupDialog(context),
          icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
        ),
        title: const Text('КАСКО Самоосмотр'),
      ),
      body: CheckupKaskoAlert(
        closeAlert: () => context.go('/polis_list'),
        iconData: Icons.done,
        text: 'Прекрасно!\nВсе необходимые фотографии загружены.'
            'Ожидайте СМС с результатом проверки.',
        textCloseAlert: 'Вернуться в приложение',
      ),
    );
  }

}
