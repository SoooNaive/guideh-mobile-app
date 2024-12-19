import 'package:flutter/material.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class SosData {
  final List<LossNotification> lossNotifications;
  final List<AccidentNotification> accidentNotifications;
  SosData(this.lossNotifications, this.accidentNotifications);
  SosData.origin(): lossNotifications = [], accidentNotifications = [];
}

class _SosPageState extends State<SosPage> with AutomaticKeepAliveClientMixin<SosPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late SosData _data;
  late Future<void> _initDataLoad;

  Future<SosData> get data async => SosData(
    await getLossNotifications(context),
    await getAccidentNotifications(context),
  );

  Future<void> _initData() async {
    _data = SosData(
      await getLossNotifications(context),
      await getAccidentNotifications(context),
    );
  }

  Future<void> _refreshData() async {
    final refreshedData = await data;
    setState(() {
      _data = refreshedData;
    });
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  Widget showData() {
    final List<LossNotification> lossNotifications = _data.lossNotifications;
    final List<AccidentNotification> accidentNotifications = _data.accidentNotifications;
    return ListView(
      children: [
        ExpansionTile(
          title: const Text('Уведомления клиента'),
          leading: itemCounterBox(lossNotifications.length),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          children: [
            const Divider(height: 1, thickness: 1),
            lossNotifications.isNotEmpty
              ? ListView.separated(
                separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                itemCount: lossNotifications.length,
                itemBuilder: (BuildContext context, int index) {
                  final LossNotification item = lossNotifications[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                    title: Text(item.docType),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(item.description),
                    ),
                    minVerticalPadding: 10,
                  );
                },
              )
            : const ListTile(title: Text('Уведомлений нет')),
          ],
        ),
        const Divider(height: 1, thickness: 1),
        ExpansionTile(
          title: const Text('Уведомления о страховых событиях'),
          leading: itemCounterBox(accidentNotifications.length),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          children: [
            const Divider(height: 1, thickness: 1),
            accidentNotifications.isNotEmpty
              ? ListView.separated(
                separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                itemCount: accidentNotifications.length,
                itemBuilder: (BuildContext context, int index) {
                  final AccidentNotification item = accidentNotifications[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                    title: Text('Полис ${item.policySeries}-${item.policyNumber}'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(item.accidentDate),
                          const SizedBox(height: 5),
                          Text(item.accidentPlace),
                          const SizedBox(height: 5),
                          Text(item.description),
                        ],
                      ),
                    ),
                    minVerticalPadding: 10,
                  );
                },
              )
              : const ListTile(title: Text('Уведомлений нет')),
          ],
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
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
                        Text('Загрузка уведомлений'),
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
          padding: const EdgeInsets.all(15),
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
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Инструкции'),
                onPressed: () => goUrl('https://guidehins.ru/uregulirovanie-straxovyx-sluchaev/'),
                style: getTextButtonStyle(
                  TextButtonStyle(theme: 'secondaryLight')
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.call_outlined),
                label: const Text('Позвонить в контакт-центр'),
                onPressed: () => makePhoneCall(globalPhoneNumber),
                style: getTextButtonStyle(
                  TextButtonStyle(theme: 'secondaryLight')
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

itemCounterBox(int count) {
  return Container(
    width: 21,
    height: 21,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black45,
    ),
    alignment: Alignment.center,
    child: Text(
      count.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    ),
  );
}

Future<List<LossNotification>> getLossNotifications(BuildContext context) async {
  final response = await Http.mobApp(
    ApiParams('MobApp', 'MP_loss_notifylist', { 'token': await Auth.token })
  );
  if (response['Error'] == 0) {
    List<LossNotification> items = [];
    for (var item in response['Data']['List']) {
      items.add(
        LossNotification(
          item['Date'],
          item['DocType'],
          item['Description'],
        )
      );
    }
    return items;
  }
  else {
    return [];
  }
}

Future<List<AccidentNotification>> getAccidentNotifications(BuildContext context) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  final body = {'UserPhone': preferences.getString('phone')};
  final response = await Http.mobApp(ApiParams('Notification', 'MP_Not_List', body));
  if (response['Error'] == 0) {
    List<AccidentNotification> items = [];
    for (var item in response['Data']) {
      items.add(
        AccidentNotification(
          item['DocId'],
          item['DocNumber'],
          item['DocDate'],
          item['Client'],
          item['PolicySeries'],
          item['PolicyNumber'],
          item['AccidentPlace'],
          item['AccidentDate'],
          item['StatusName'],
          item['Description'],
        )
      );
    }
    return items;
  }
  else {
    return [];
  }
}

class LossNotification {
  final String date;
  final String docType;
  final String description;

  LossNotification(
    this.date,
    this.docType,
    this.description,
  );
}

class AccidentNotification {
  final String docId;
  final String docNumber;
  final String docDate;
  final String client;
  final String policySeries;
  final String policyNumber;
  final String accidentPlace;
  final String accidentDate;
  final String statusName;
  final String description;

  AccidentNotification(
    this.docId,
    this.docNumber,
    this.docDate,
    this.client,
    this.policySeries,
    this.policyNumber,
    this.accidentPlace,
    this.accidentDate,
    this.statusName,
    this.description,
  );
}
