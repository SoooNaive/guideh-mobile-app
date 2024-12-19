import 'package:flutter/material.dart';
import 'package:guideh/services/functions.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
      ),
      body: ListView(
        // padding: const EdgeInsets.all(8),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
            child: Image.asset('assets/images/guideh-logo.png'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Официальное приложение АО "Страховая компания ГАЙДЕ".'),
                const SizedBox(height: 10),
                Text('Версия приложения $appVersion'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          GestureDetector(
            child: const ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('Политика конфиденциальности', style: TextStyle(
                color: Colors.grey, decoration: TextDecoration.underline)),
            ),
            onTap: () => goUrl(privacyPolicyUrl),
          ),
          const Divider(height: 1),
          GestureDetector(
            child: const ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('Пользовательское соглашение', style: TextStyle(
                color: Colors.grey, decoration: TextDecoration.underline)),
            ),
            onTap: () => goUrl(userAgreementUrl),
          ),
          const Divider(height: 1),
          GestureDetector(
            child: const ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('Условия использования Яндекс.Карт', style: TextStyle(
                color: Colors.grey, decoration: TextDecoration.underline)),
            ),
            onTap: () => goUrl('https://yandex.ru/legal/maps_termsofuse/index.html'),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
