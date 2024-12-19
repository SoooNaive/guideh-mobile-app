import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/b2b/b2b_auth_dialog.dart';


class B2BPage extends StatefulWidget {
  const B2BPage({super.key});

  @override
  State<B2BPage> createState() => _B2BPageState();
}

class _B2BPageState extends State<B2BPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        ListTile(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Text('Авторизация в B2B'),
          ),
          subtitle: const Text('Подтверждение запроса на авторизацию'),
          leading: const Icon(Icons.login),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog(
            context: context,
            builder: (BuildContext dialogContext) => B2BAuthDialog(
              dialogContext: dialogContext,
            ),
          ),
          minVerticalPadding: 15,
          horizontalTitleGap: 10,
          titleAlignment: ListTileTitleAlignment.center,
        ),

        const Divider(height: 1),

        ListTile(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Text('Договоры ОСАГО'),
          ),
          subtitle: const Text('Список ваших договоров'),
          leading: const Icon(Icons.list_alt),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.pushNamed('b2b_osago_list');
          },
          minVerticalPadding: 15,
          horizontalTitleGap: 10,
          titleAlignment: ListTileTitleAlignment.center,
        ),

        const Divider(height: 1),

      ],
    );
  }
}
