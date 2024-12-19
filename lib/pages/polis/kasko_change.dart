import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/my_title.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/theme/theme.dart';

class KaskoChangePage extends StatefulWidget {
  final Policy policy;
  const KaskoChangePage({super.key, required this.policy});

  @override
  State<KaskoChangePage> createState() => _KaskoChangePageState();
}

class _KaskoChangePageState extends State<KaskoChangePage> {
  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Внести изменения'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            MyTitle('Полис ${policy.type} №${policy.docNumber}'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      icon: const Icon(Icons.groups),
                      label: const Text('Изменить водителей'),
                      style: getTextButtonStyle(),
                      onPressed: () => context.go(
                        '/polis_list/policy/kasko_change/drivers',
                        extra: policy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).toList(),
      ),
    );
  }
}
