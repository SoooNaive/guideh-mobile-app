import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class B2BOsagoList extends StatefulWidget {
  const B2BOsagoList({super.key});

  @override
  State<B2BOsagoList> createState() => _B2BOsagoListState();
}

class _B2BOsagoListState extends State<B2BOsagoList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
    GlobalKey<RefreshIndicatorState>();
  List<B2BPolicy> _list = [];
  late Future<void> _initDataLoad;

  Future<List<B2BPolicy>> get data async => await getList();
  Future<void> _initData() async => _list = await getList();
  Future<void> _refreshData() async {
    final refreshedData = await data;
    setState(() => _list = refreshedData);
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  Widget showData() {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        final B2BPolicy policy = _list[index];
        return Material(
          color: Colors.white,
          child: InkWell(
            child: ListTile(
              trailing: policy.status == 'В ожидании обработки'
                ? const Icon(Icons.access_time_outlined)
                : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              title: Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 12),
                  Text(policy.docNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  if (policy.insurer.isNotEmpty) Text(policy.insurer, style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  )),
                  if (policy.objectName.isNotEmpty) Text(policy.objectName, style: const TextStyle(height: 1.3)),
                  Text('Заключён: ${policy.dateEnd}', style: const TextStyle(height: 1.3)),
                  Text('Статус: ${policy.status}', style: const TextStyle(height: 1.3)),
                ],
              ),
              minVerticalPadding: 7,
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Открыть полис в B2B?'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (policy.docNumber.isNotEmpty) Text('Полис № ${policy.docNumber}'),
                      const SizedBox(height: 5),
                      if (policy.insurer.isNotEmpty) Text('Страхователь: ${policy.insurer}'),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Отмена'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      onPressed: () => goUrl(
                        'https://lk.guideh.com/osago20/case/?id=${policy.docId}',
                        mode: LaunchMode.externalApplication,
                      ),
                      style: TextButton.styleFrom(backgroundColor: secondaryLightColor),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Открыть B2B'),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Полисы ОСАГО'),
      ),

      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
                future: _initDataLoad,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                    case ConnectionState.active: {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 15),
                            Text('Загрузка списка'),
                          ],
                        ),
                      );
                    }
                    case ConnectionState.done: {
                      return RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _refreshData,
                        child: showData(),
                      );
                    }
                  }
                }
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(80),
                  spreadRadius: 2,
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  onPressed: () => context.pushNamed('b2b_osago_add'),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Новый договор ОСАГО'),
                  style: getTextButtonStyle(TextButtonStyle()),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<B2BPolicy>> getList() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_OSAGO', {
        'token': await Auth.token,
        'Method': 'OSAGOAgentList',
        'AgentId': preferences.getString('agentId')
      })
    );
    if (response['Error'] == 0) {
      List<B2BPolicy> items = [];
      for (var item in response['List']) {
        items.add(
          B2BPolicy(
            item['Id'],
            item['Number'],
            item['Date'],
            item['Auto'],
            item['Insurer'],
            item['Status'],
          )
        );
      }
      return items;
    }
    else {
      return [];
    }
  }

}

class B2BPolicy {
  final String docId;
  final String docNumber;
  final String dateEnd;
  final String objectName;
  final String insurer;
  final String status;

  B2BPolicy(
    this.docId,
    this.docNumber,
    this.dateEnd,
    this.objectName,
    this.insurer,
    this.status,
  );

}