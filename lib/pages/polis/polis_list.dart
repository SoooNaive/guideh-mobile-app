import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/scaffold/scaffold_bloc.dart';
import 'package:guideh/pages/dms/models/policy_dms.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/pages/polis/banner_slider.dart';
import 'package:guideh/services/http.dart';

import 'load_data_dms.dart';

Widget _getPolicyTypeIcon(String policyType) {
  var title = policyType.toUpperCase();
  if (title.startsWith('КВАРТИРА') || title.contains('КВАРТИР')) {
    title = 'КВАРТИРА';
  } else if (title.startsWith('НС')) {
    title = 'НС';
  }
  title = title.startsWith('КВАРТИРА') ? 'КВАРТИРА' : title;
  switch(title) {
    case 'КАСКО':
    case 'ОСАГО':
      return const Icon(Icons.directions_car_filled);
    case 'ДМС':
      return const Icon(Icons.health_and_safety);
    case 'ТУРИСТ':
      return const Icon(Icons.flight);
    case 'КВАРТИРА':
    case 'ИПОТЕКА':
      return const Icon(Icons.home);
    case 'НС':
      return const Icon(Icons.personal_injury);
    default: return const Icon(Icons.shield_outlined);
  }
}

class PolicyCard extends StatelessWidget {
  final Policy policy;
  const PolicyCard({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          title: Row(
            children: [
              _getPolicyTypeIcon(policy.type),
              const SizedBox(width: 12),
              Text(
                policy.type,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(' ${policy.docNumber}'),
            ],
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text('Страхователь: ${policy.insurer}'),
              policy.objectName.isNotEmpty
                ? Text(policy.objectName)
                : const SizedBox.shrink(),
              Text('Действует до: ${policy.dateEnd}'),
            ],
          ),
          minVerticalPadding: 10,
          trailing: const Icon(Icons.more_vert),
        ),
        onTap: () => context.go('/polis_list/policy', extra: policy),
      ),
    );
  }
}


class PoliciesList extends StatefulWidget {
  final bool? updateListPolis;
  const PoliciesList({super.key, this.updateListPolis});

  @override
  State<PoliciesList> createState() => _PoliciesListState();
}

class _PoliciesListState extends State<PoliciesList> with AutomaticKeepAliveClientMixin<PoliciesList> {
  late List<Policy> _policies;
  late List<PolicyDMS> _policiesDMS;
  late Future<void> _initDataLoad;

  bool isLoading = false;

  Future<List<Policy>> get data async => await getPolicies(true);
  Future<List<PolicyDMS>> get dataDMS async => await getPoliciesDMS();

  Future<void> _initData() async {
    _policies = await getPolicies(false);
    _policiesDMS = await getPoliciesDMS();
  }

  Future<void> _refreshData() async {
    final refreshedData = await data;
    final refreshedDataDMS = await dataDMS;
    setState(() {
      _policies = refreshedData;
      _policiesDMS = refreshedDataDMS;
      isLoading = false;
    });
  }

  Future<List<Policy>> getPolicies([bool updateListPolis = false]) async {
    final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_list_polis', {
        'token': await Auth.token,
        'UpdateListPolis': updateListPolis,
      })
    );

    List<Policy> policies = [];

    if (response['Error'] == 0) {
      var jsonData = response['Data'];
      for (var item in jsonData) {
        Policy policy = Policy(
          item["Type"],
          item["DocId"],
          item["DocNumber"],
          item["DocDate"],
          item["DateS"],
          item["DateE"],
          item["DateEnd"],
          item["ObjectName"],
          item["Description"],
          item["Insurer"],
          item["Print"],
          item["Role"],
          item["Active"],
        );
        policies.add(policy);
      }
    }
    else if (response['Error'] == 1) {
      if (mounted) {
        Auth.logout(context, true);
      }
    }
    return policies;
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  Widget showData() {
    final scaffoldBloc = BlocProvider.of<ScaffoldBloc>(context);

    final List<Policy> activePolicies = _policies.where((item) => item.active).toList();
    final List<Policy> archivedPolicies = _policies.where((item) => !item.active).toList();

    return Stack(
      children: [
        ListView(
          children: [
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Действующие полисы'),
              leading: const Icon(Icons.verified_user),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              children: [
                const Divider(height: 1, thickness: 1),
                activePolicies.isNotEmpty
                  ? ListView.separated(
                    separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    itemCount: activePolicies.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Policy policy = activePolicies[index];
                      return PolicyCard(policy: policy);
                    },
                  )
                  : _policiesDMS.isNotEmpty
                    ? const SizedBox.shrink()
                    : const ListTile(title: Text('Нет полисов')),
                if (_policiesDMS.isNotEmpty) Column(
                  children: [
                    const Divider(height: 1, thickness: 2),
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        child: const ListTile(
                          title: Text('Полисы ДМС'),
                          leading: Icon(Icons.health_and_safety),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          minVerticalPadding: 10,
                          trailing: Icon(Icons.more_vert),
                        ),
                        onTap: () {
                          scaffoldBloc.add(ScaffoldGoToTabEvent(1));
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
            const Divider(height: 1, thickness: 1),
            archivedPolicies.isNotEmpty
                ? Column(
              children: [
                ExpansionTile(
                  title: const Text('Архивные полисы'),
                  leading: const Icon(Icons.archive),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  children: [
                    const Divider(height: 1, thickness: 1),
                    ListView.separated(
                      separatorBuilder: (BuildContext context, int index) => const Divider(height: 1, thickness: 1),
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      itemCount: archivedPolicies.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Policy policy = archivedPolicies[index];
                        return PolicyCard(policy: policy);
                      },
                    ),
                  ],
                ),
                const Divider(height: 1, thickness: 1),
              ],
            )
                : const SizedBox.shrink(),
          ],
        ),
        // todo: поменять на floating action button
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 12),
            child: ElevatedButton(
              onPressed: () {
                setState(() => isLoading = true);
                _refreshData();
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                elevation: 4,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.fromLTRB(12, 12, 15, 12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync),
                  SizedBox(width: 6),
                  Text('Обновить'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FutureBuilder(
            future: _initDataLoad,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text('Загрузка полисов'),
                      SizedBox(height: 5),
                      Text('Пожалуйста, подождите'),
                    ],
                  ),
                );
              }
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
                        Text('Загрузка полисов'),
                        // SizedBox(height: 5),
                        // Text('Пожалуйста, подождите'),
                      ],
                    ),
                  );
                }
                case ConnectionState.done: {
                  return showData();
                }
              }
            }
          ),
        ),
        const BannerSlider(),
      ],
    );
  }
}
