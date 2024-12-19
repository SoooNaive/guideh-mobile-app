import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:guideh/theme/theme.dart';

import 'package:guideh/pages/polis/load_data_dms.dart';
import 'package:guideh/pages/dms/models/policy_dms.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/layout/my_title.dart';

import 'dms_functions.dart';


class DMS extends StatefulWidget {
  final List<PolicyDMS>? policiesDMS;
  const DMS({super.key, this.policiesDMS});

  @override
  State<DMS> createState() => _DMSState();
}


class _DMSState extends State<DMS> with AutomaticKeepAliveClientMixin<DMS> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  late List<PolicyDMS>? _policiesDMS;
  late Future<void>? _initDataLoad;

  Future<void> _refreshData() async {
    final refreshedData = await getPoliciesDMS();
    setState(() {
      _policiesDMS = refreshedData;
      _showBottomButtons = _policiesDMS!.length > 1;
    });
  }

  Future<void> _initData() async {
    final loadedData = await getPoliciesDMS();
    setState(() {
      _policiesDMS = loadedData;
      _showBottomButtons = _policiesDMS!.length > 1;
    });
  }

  bool _showBottomButtons = false;

  @override
  void initState() {
    super.initState();
    _policiesDMS = widget.policiesDMS;
    _initDataLoad = _policiesDMS == null
      ? _initData()
      : null;
  }

  Widget showData() {
    if (_policiesDMS == null || _policiesDMS!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _policiesDMS == null
          ? const Text('Ошибка загрузки полисов ДМС.\nПопробуйте обновить позже.', textAlign: TextAlign.center)
          : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              SizedBox(height: 20),
              const Text('Полисы этого вида не добавлены.\nЕсли хотите добавить Полис, свяжитесь с нами'),
              SizedBox(height: 30),
              TextButton.icon(
                icon: const Icon(Icons.call_outlined),
                label: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: const Text('8 (800) 555-15-70'),
                ),
                onPressed: () => makePhoneCall(dmsSosPhoneNumber),
                style: getTextButtonStyle(
                    TextButtonStyle(theme: 'secondary', size: 2)
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Федеральный контактный центр',
                style: TextStyle(color: Colors.black45),
                textAlign: TextAlign.center,
              ),

            ],
          ),
      );
    }
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [

          if (_policiesDMS!.length > 1) const MyTitle('Мои полисы ДМС'),
          if (_policiesDMS!.length == 1) const SizedBox(height: 16),

          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _policiesDMS!.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              final PolicyDMS policy = _policiesDMS![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Row(
                      children: [

                        Icon(
                          Icons.medical_services,
                          size: 20,
                          color: Color(0xFFCFCFCF),
                        ),

                        SizedBox(width: 10),

                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Полис: ${policy.docNumber}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        Spacer(),

                        MenuAnchor(
                          style: const MenuStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
                                vertical: 4, horizontal: 0
                            )),
                          ),
                          menuChildren: [

                            // [Посмотреть]
                            MenuItemButton(
                              onPressed: () => dmsShowFile(
                                context,
                                'Полис',
                                policy.docId,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Посмотреть'),
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: Color(0xFFEEEEEE)),

                            // [Скачать электронный полис]
                            MenuItemButton(
                              onPressed: () => dmsDownloadFile(
                                context,
                                'Полис',
                                policy.docId,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.download, size: 20),
                                  SizedBox(width: 12),
                                  Text('Скачать электронный полис'),
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: Color(0xFFEEEEEE)),

                            // [Отправить себе]
                            MenuItemButton(
                              onPressed: () => dmsSendDataToEmail(
                                context,
                                'Полис',
                                policy.docId,
                                policy.docId,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Отправить себе'),
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: Color(0xFFEEEEEE)),

                            // [Отправить на другой email]
                            MenuItemButton(
                              onPressed: () => dmsShowModalWithEmailInput(
                                context,
                                'Полис',
                                policy.docId,
                                policy.docId,
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.mail_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Отправить на другой email'),
                                ],
                              ),
                            ),

                          ],
                          builder: (_, MenuController controller, Widget? child) {
                            return IconButton(
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: secondaryLightColor,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              color: primaryColor,
                              icon: const Icon(Icons.more_vert),
                            );
                          },
                        ),

                      ],
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Divider(height: 14, color: Color(0xFFF0F0F0)),

                        const SizedBox(height: 3),
                        Text('Действует: ${policy.dateS.substring(0, 10)} – ${policy.dateE.substring(0, 10)}'),
                        const SizedBox(height: 6),
                        Text('Страхователь: ${policy.insurer}'),
                        const SizedBox(height: 6),
                        Text('Застрахованный: ${policy.insured}'),

                        Divider(height: 25, color: Color(0xFFF0F0F0)),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Список ЛПУ
                            Flexible(
                              flex: 6,
                              child: TextButton(
                                onPressed: () => context.goNamed(
                                  'dms_lpu',
                                  queryParameters: {
                                    'policy_id': policy.docId
                                  },
                                ),
                                style: getTextButtonStyle(
                                    TextButtonStyle(theme: 'secondaryLight', size: 1)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.domain_add),
                                    SizedBox(height: 6),
                                    const Text(
                                      'Список ЛПУ',
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: 8),

                            // Запись к врачу
                            Flexible(
                              flex: 8,
                              child: TextButton(
                                onPressed: () => context.goNamed(
                                  'dms_add_req',
                                  queryParameters: {
                                    'policy_id': policy.docId,
                                  },
                                ),
                                style: getTextButtonStyle(
                                    TextButtonStyle(theme: 'secondaryLight', size: 1)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.medical_information_outlined),
                                    SizedBox(height: 6),
                                    const Text(
                                      'Запись к врачу',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(width: 8),

                            // Программа
                            Flexible(
                              flex: 6,
                              child: MenuAnchor(
                                menuChildren: [

                                  // [Посмотреть программу]
                                  MenuItemButton(
                                    onPressed: () => dmsDownloadFile(
                                      context,
                                      'ПрограммаСтрахования',
                                      policy.docId,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.download, size: 20),
                                        SizedBox(width: 12),
                                        Text('Посмотреть'),
                                      ],
                                    ),
                                  ),

                                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                                  // [Отправить себе]
                                  MenuItemButton(
                                    onPressed: () => dmsSendDataToEmail(
                                      context,
                                      'ПрограммаСтрахования',
                                      policy.docId,
                                      policy.docId,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Отправить себе'),
                                      ],
                                    ),
                                  ),

                                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                                  // [Отправить на другой email]
                                  MenuItemButton(
                                    onPressed: () => dmsShowModalWithEmailInput(
                                      context,
                                      'ПрограммаСтрахования',
                                      policy.docId,
                                      policy.docId,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.mail_outline, size: 20),
                                        SizedBox(width: 12),
                                        Text('Отправить на другой email'),
                                      ],
                                    ),
                                  ),

                                ],
                                builder: (_, MenuController controller, Widget? child) {
                                  return TextButton(
                                    onPressed: () {
                                      if (controller.isOpen) {
                                        controller.close();
                                      } else {
                                        controller.open();
                                      }
                                    },
                                    style: getTextButtonStyle(
                                        TextButtonStyle(theme: 'secondaryLight', size: 1)
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.article_outlined),
                                        SizedBox(height: 6),
                                        const Text(
                                          'Программа',
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 8),

                        // Гарантийные письма
                        TextButton.icon(
                          icon: const Icon(Icons.mail_outline),
                          label: const Text('Гарантийные письма'),
                          onPressed: () => context.goNamed(
                            'letters_of_guarantee',
                            queryParameters: {
                              'policy_id': policy.docId,
                              'policy_number': policy.docNumber,
                            },
                          ),
                          style: getTextButtonStyle(
                              TextButtonStyle(theme: 'secondaryLight', size: 1)
                          ),
                        ),

                        const SizedBox(height: 8),

                        // История обращений
                        TextButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('История обращений'),
                          onPressed: () => context.go('/dms/history'),
                          style: getTextButtonStyle(
                            TextButtonStyle(theme: 'secondaryLight', size: 1)
                          ),
                        ),

                        if (!_showBottomButtons) Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              btnCallSos(1),
                              const SizedBox(height: 8),
                              btnCallAmbulance(1),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 5),
        ],
      ),
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
          child: _policiesDMS == null
            ? FutureBuilder(
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
                          Text('Загрузка полисов'),
                        ],
                      ),
                    );
                  }
                  case ConnectionState.done: {
                    return showData();
                  }
                }
              }
            )
            : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              child: showData(),
            ),
        ),

        // нижние кнопки - отображаем, если полисов больше одного
        if (_showBottomButtons) Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                spreadRadius: 3,
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              btnCallSos(2),
              const SizedBox(height: 10),
              btnCallAmbulance(2),
            ],
          ),
        ),

      ],
    );
  }

  // [Позвонить в диспетчерскую]
  Widget btnCallSos(int size) => TextButton.icon(
    icon: const Icon(Icons.call_outlined),
    label: const Text(
      'Позвонить в диспетчерскую',
      textAlign: TextAlign.center,
    ),
    onPressed: () => makePhoneCall(dmsSosPhoneNumber),
    style: getTextButtonStyle(
        TextButtonStyle(theme: 'secondaryLight', size: size)
    ),
  );

  // [Экстренный вызов скорой помощи]
  Widget btnCallAmbulance(int size) => TextButton.icon(
    icon: const Icon(Icons.call_outlined),
    label: const Text(
      'Экстренный вызов скорой помощи',
      textAlign: TextAlign.center,
    ),
    onPressed: () => makePhoneCall(ambulancePhoneNumber),
    style: getTextButtonStyle(
      TextButtonStyle(theme: 'secondaryAccent', size: size)
    ),
  );

}
