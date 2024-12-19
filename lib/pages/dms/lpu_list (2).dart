import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'lpu_list_search_field.dart';
import 'models/lpu.dart';
import 'models/lpu_risk.dart';


class DmsLpuList extends StatefulWidget {
  final String policyId;
  // функция для передачи координат выбранного ЛПУ для перехода на карте
  final Function(Point point)? goToMapPoint;
  // функция для передачи ЛПУ в родительский виджет
  final Function(DmsLpu lpu)? returnLPU;
  const DmsLpuList({
    super.key,
    this.returnLPU,
    required this.policyId,
    this.goToMapPoint,
  });

  @override
  State<DmsLpuList> createState() => _DmsLpuListState();
}


// class _ClearButton extends StatelessWidget {
//   const _ClearButton({required this.controller});
//
//   final TextEditingController controller;
//
//   @override
//   Widget build(BuildContext context) => IconButton(
//     icon: const Icon(Icons.clear),
//     onPressed: () => controller.clear(),
//   );
// }


class _DmsLpuListState extends State<DmsLpuList> with AutomaticKeepAliveClientMixin<DmsLpuList> {

  @override
  bool get wantKeepAlive => true;

  late String polisId;
  late final List<DmsLpuRisk> lpuRiskList;
  List<DmsLpuRisk>? lpuRiskListFiltered;
  late Future<void> _initDataLoad;
  Future<void> _initData() async {
    lpuRiskList = await getDmsLpuList();
  }

  @override
  void initState() {
    super.initState();
    polisId = widget.policyId;
    _initDataLoad = _initData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // если это содержимое таба – НЕ оборачиваем в скаффолд
    if (widget.returnLPU == null) {
      return _futureBuilder();
    }

    // если это выбор ЛПУ из формы записи к врачу – оборачиваем в скаффолд
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите ЛПУ'),
      ),
      body: _futureBuilder(widget.returnLPU),
    );

  }

  Widget _futureBuilder([Function? returnLPU]) => FutureBuilder(
    future: _initDataLoad,
    builder: (context, snapshot) {
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
          return _showData(returnLPU);
        }
      }
    },
  );

  _updateRiskListFiltered(List<DmsLpuRisk>? list) {
    setState(() => lpuRiskListFiltered = list ?? lpuRiskList);
  }

  int _getLpuCount() {
    int count = 0;
    for(var risk in lpuRiskListFiltered ?? <DmsLpuRisk>[]) {
      count = count + risk.lpu.length;
    }
    return count;
  }

  Widget _showData([Function? returnLPU]) {
    final onTapReturnLPU = returnLPU != null;
    print(lpuRiskListFiltered);
    lpuRiskListFiltered ??= lpuRiskList;
    print(lpuRiskListFiltered!.length);
    return Column(
      children: [

        // поиск
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
          child: DmsLpuListSearch(
              lpuRiskList: lpuRiskList,
              lpuCount: _getLpuCount(),
              updateRiskListFiltered: _updateRiskListFiltered
          ),
        ),

        const Divider(height: 1),

        Expanded(
          child: SingleChildScrollView(
            child: lpuRiskListFiltered!.isEmpty
              ? const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('Не найдено')
              )
              : Column(
                children: [

                  // лист рисков
                  ListView.separated(
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      separatorBuilder: (BuildContext context, int indexLpu) => const Divider(height: 1),
                      itemCount: lpuRiskListFiltered!.length,
                      itemBuilder: (BuildContext context, int indexRisk) {
                        final DmsLpuRisk risk = lpuRiskListFiltered![indexRisk];
                        if (risk.lpu.isEmpty) return null;
                        return Column(
                          children: [

                            // панель названия риска
                            ExpansionTile(
                              title: Text(
                                risk.risk,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4, bottom: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                    decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                      color: Color(0xffeeeeee),
                                    ),
                                    child: Text(
                                      risk.lpu.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.white,
                              children: [
                                const Divider(height: 1),

                                // лист ЛПУшек
                                ListView.separated(
                                    shrinkWrap: true,
                                    physics: const ScrollPhysics(),
                                    separatorBuilder: (BuildContext context, int indexLpu) => const Divider(height: 1),
                                    itemCount: risk.lpu.length,
                                    itemBuilder: (BuildContext context, int indexLpu) {
                                      final DmsLpu lpu = risk.lpu[indexLpu];
                                      return onTapReturnLPU

                                        // панель ЛПУ ( → возврат в форму записи)
                                        ? ListTile(
                                            leading: const Icon(Icons.domain_add),
                                            title: Text(lpu.name),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                lpu.address,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13
                                                ),
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              returnLPU(
                                                  DmsLpu(
                                                    id: lpu.id,
                                                    name: lpu.name,
                                                    address: lpu.address,
                                                  )
                                              );
                                            },
                                          )

                                        // панель ЛПУ (раскрывающаяся)
                                        : ExpansionTile(
                                          leading: const Icon(Icons.domain_add),
                                          title: Text(lpu.name),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              lpu.address,
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13
                                              ),
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                                          children: [
                                            ((lpu.latitude ?? '') != '' && (lpu.longitude ?? '') != '')
                                                ? TextButton.icon(
                                              onPressed: () {
                                                DefaultTabController.of(context).animateTo(1);
                                                widget.goToMapPoint!(
                                                    Point(
                                                      latitude: double.parse(lpu.latitude!),
                                                      longitude: double.parse(lpu.longitude!),
                                                    )
                                                );
                                              },
                                              style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                                              icon: const Icon(Icons.pin_drop_outlined),
                                              label: const Text('Показать на карте'),
                                            )
                                                : const SizedBox.shrink(),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: () => context.goNamed(
                                                'dms_lpu_add_req',
                                                queryParameters: {
                                                  'policy_id': polisId,
                                                },
                                                extra: DmsLpu(
                                                  id: lpu.id,
                                                  name: lpu.name,
                                                  address: lpu.address,
                                                ),
                                              ),
                                              style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                                              icon: const Icon(Icons.medical_information_outlined),
                                              label: const Text('Записаться к врачу'),
                                            ),
                                            if (lpu.phones != null) ...lpu.phones!.map((phone) {
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: TextButton.icon(
                                                  onPressed: () => makePhoneCall(phone),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: primaryLightColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.fromHeight(48),
                                                  ),
                                                  icon: const Icon(Icons.call_outlined),
                                                  label: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      const Text('Позвонить в ЛПУ'),
                                                      Text(phone, style: TextStyle(
                                                        color: Colors.black45,
                                                        fontSize: 13,
                                                        height: 1.35
                                                      )),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ]
                                        );

                                    }
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    ),
                  const Divider(height: 1),
                ],
              ),
          ),
        ),
      ],
    );
  }

  Future<List<DmsLpuRisk>> getDmsLpuList() async {
    var body = {
      'token': await Auth.token,
      'PolisId': polisId,
    };
    final response = await Http.mobApp(
        ApiParams('MobApp', 'MP_dms_polis_lpu', body)
    );

    if (response['Error'] == 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['Message'] ?? 'Ошибка'),
          ),
        );
      }
      return [];
    }
    else if (response['Error'] == 1) {
      if (mounted) {
        Auth.logout(context, true);
      }
      return [];
    }
    else if (response['Error'] == 0) {
      List<DmsLpuRisk> risks = [];
      for (var risk in response['Data']) {
        List<DmsLpu> lpus = [];
        for (var lpu in risk['LPU']) {
          lpus.add(
            DmsLpu(
              id: lpu['Id'],
              name: lpu['Name'],
              address: lpu['Address'],
              latitude: lpu['Latitude'],
              longitude: lpu['Longitude'],
              phones: List<String>.from(lpu['Phones']),
            )
          );
        }
        risks.add(
          DmsLpuRisk(
            risk['Risk'],
            lpus,
          )
        );
      }
      return risks;
    }
    else {
      return [];
    }
  }

}
