import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/my_title.dart';
import 'package:guideh/pages/polis/send_client_request.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/services/pdf_viewer.dart';
import 'package:guideh/theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/policy.dart';

class DetailPage extends StatefulWidget {
  final Policy policy;
  const DetailPage({super.key, required this.policy});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with WidgetsBindingObserver {

  bool isLoading = false;
  late bool pushesIsGranted;

  // если ОСАГО - грузим признак, как отображать [пролонгация]
  bool canOsagoProlong = false;
  String? linkQr;

  bool osagoProlongIsPending = false;
  bool osagoProlongIsFetching = false;
  bool osagoProlongIsRejected = false;
  bool osagoProlongIsDone = false;
  bool? osagoProlongIsAccepted;

  bool osagoProlongLegalIsFetching = false;
  bool osagoProlongLegalIsPending = false;

  double? osagoProlongPremium;
  String? osagoProlongDocId;

  late Future<void> _initDataLoadOsago;
  Future<void> _initDataOsago() async {
    pushesIsGranted = await Permission.notification.isGranted;
    if (widget.policy.type == 'ОСАГО') {
      final canOsagoProlongResponse = await loadCanOsagoProlong(widget.policy.docId);
      canOsagoProlong = canOsagoProlongResponse?['can_osago_prolong'] == true;
      if (canOsagoProlongResponse?['ProlPolis']?['AddStatus'] == 'Акцептирован в РСА') {
        osagoProlongIsAccepted = true;
        return;
      }
      osagoProlongDocId = canOsagoProlongResponse?['ProlPolis']?['DocId'];
      final double? premium = canOsagoProlongResponse?['ProlPolis']?['Premium'];
      // премия пришла
      if ((premium ?? 0) != 0) {
        osagoProlongPremium = premium;
        final osagoProlongStatus = canOsagoProlongResponse?['ProlPolis']?['AddStatus'];
        // qr пришёл
        if (osagoProlongStatus == 'Ожидает оплаты') {
          osagoProlongIsDone = true;
          linkQr = canOsagoProlongResponse?['ProlPolis']?['LinkQR'];
        }
        // ожидание qr-а
        else if (osagoProlongStatus == 'Проект проверен') {
          osagoProlongIsDone = true;
        }
      }
      else {
        switch (canOsagoProlongResponse?['ProlPolis']?['AddStatus']) {
          case 'Создан проект':
            osagoProlongIsPending = true;
            break;
          case 'Проект отклонен':
            osagoProlongIsRejected = true;
            break;
        }
      }
    }
  }

  Future<void> _fetchOsagoProlong(String docId) async {
    setState(() => osagoProlongIsFetching = true);
    Map<String, dynamic> response;
    double? premium;
    String? prolongDocId;
    int attempts = 0;
    // три попытки
    await Future.delayed(const Duration(seconds: 2));
    while ((premium == null || premium == 0) && attempts < 3 && mounted) {
      attempts += 1;
      response = await loadCanOsagoProlong(docId);
      premium = response['ProlPolis']?['Premium'].toDouble();
      prolongDocId = response['ProlPolis']?['DocId'];
      if (premium == null || premium == 0) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    if (!mounted) return;
    setState(() {
      osagoProlongDocId = prolongDocId;
      osagoProlongIsFetching = false;
      if ((premium ?? 0) != 0) {
        osagoProlongIsDone = true;
        osagoProlongPremium = premium;
      }
      else {
        osagoProlongIsPending = true;
      }
    });
  }

  Future<void> _fetchOsagoLegal(String docId) async {
    String? gotLinkQr;
    Map<String, dynamic> response;
    int attempts = 0;
    // 4 попытки
    await Future.delayed(const Duration(seconds: 1));
    while (gotLinkQr == null && attempts < 4 && mounted) {
      attempts += 1;
      response = await loadCanOsagoProlong(docId);
      gotLinkQr = response['ProlPolis']?['LinkQR'];
      if (gotLinkQr == null || gotLinkQr == '') {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    if (!mounted) return;
    if (gotLinkQr != null) {
      setState(() {
        linkQr = gotLinkQr;
        try {
          goUrl(gotLinkQr!, mode: LaunchMode.externalApplication);
        } catch(e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось перейти по ссылке на оплату. Попробуйте позже.'),
            ),
          );
        }
        osagoProlongLegalIsFetching = false;
      });
    }
    else {
      setState(() {
        osagoProlongLegalIsPending = true;
        osagoProlongLegalIsFetching = false;
      });
    }
  }

  Future<bool> _fetchOsagoAccepted(String docId) async {
    Map<String, dynamic> response;
    int attempts = 0;
    String? addStatus;
    const String targetStatus = 'Акцептирован в РСА';
    // 3 попытки
    await Future.delayed(const Duration(seconds: 1));
    while (addStatus != targetStatus && attempts < 3 && mounted) {
      attempts += 1;
      response = await loadCanOsagoProlong(docId);
      addStatus = response['ProlPolis']?['AddStatus'];
      if (addStatus != targetStatus) {
        await Future.delayed(const Duration(seconds: 3));
      }
    }
    if (!mounted) return false;
    return addStatus == targetStatus;
  }

  @override
  void initState() {
    super.initState();
    _initDataLoadOsago = _initDataOsago();
    WidgetsBinding.instance.addObserver(this);
  }

  // следим за лайф-сайклом виджета
  // ожидаем статус 'резумэд' - считаем, что вернулся после СБП
  AppLifecycleState? _widgetLifecycleStatue;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!mounted) return;
    setState(() => _widgetLifecycleStatue = state);
    if (state == AppLifecycleState.resumed && linkQr != null) {
      final bool osagoProlongIsAcceptedAnswer = await _fetchOsagoAccepted(widget.policy.docId);
      if (!mounted) return;
      setState(() {
        osagoProlongIsAccepted = osagoProlongIsAcceptedAnswer;
      });
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Policy policy = widget.policy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о полисе'),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : FutureBuilder(
          future: _initDataLoadOsago,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active: {
                return const Center(child: CircularProgressIndicator());
              }
              case ConnectionState.done: {

                // todo: про пуши пишем только на андроиде
                String pleaseWaitResponseMessage = 'Зайдите в приложение позже';
                if (Platform.isAndroid && pushesIsGranted) {
                  pleaseWaitResponseMessage += 'или ожидайте push-сообщение';
                }
                pleaseWaitResponseMessage += '.';

                return ListView(
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: [

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [

                            MyTitle('Полис ${policy.type}'),

                            if (osagoProlongIsPending || osagoProlongIsRejected || osagoProlongIsFetching) Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: const BoxDecoration(
                                    color: Color(0xffefe6c8),
                                    borderRadius: BorderRadius.all(Radius.circular(5))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (!osagoProlongIsPending) const SizedBox(height: 5),
                                    Text(
                                      osagoProlongIsPending
                                        ? "Запрос на пролонгацию полиса принят. $pleaseWaitResponseMessage"
                                        : osagoProlongIsRejected
                                          ? "Запрос на пролонгацию полиса отклонён"
                                          : "Запрос на пролонгацию полиса, подождите...",
                                      style: const TextStyle(
                                        color: Color(0xff78610a),
                                        fontSize: 16,
                                      )
                                    ),
                                    if (osagoProlongIsFetching) Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(0xffe0d5ab),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                        onPressed: null,
                                        child: const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xff78610a),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )

                            else if (osagoProlongIsDone) Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xffd4efb6),
                                  borderRadius: BorderRadius.all(Radius.circular(5))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 5),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Страховая премия для пролонгации: ',
                                        style: const TextStyle(
                                          color: Color(0xff0d360a),
                                          fontSize: 16,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: osagoProlongPremium.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: ' руб.'),
                                          if (linkQr != null && osagoProlongIsAccepted == null)
                                            const TextSpan(text: ' Ожидается оплата.'),
                                        ]
                                      )
                                    ),
                                    const SizedBox(height: 10),

                                    if (osagoProlongLegalIsFetching) TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color(0xffb8d991),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      onPressed: null,
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Color(0xff134b0f),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )

                                    else if (osagoProlongLegalIsPending) Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        "Заявка принята. Оформление займёт какое-то время. $pleaseWaitResponseMessage",
                                        style: const TextStyle(color: Color(0xff0d360a)),
                                      ),
                                    )

                                    else if (linkQr != null) _widgetLifecycleStatue == AppLifecycleState.resumed

                                        ? osagoProlongIsAccepted == null
                                          ? TextButton.icon(
                                            icon: const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Color(0xff134b0f),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            label: const Text(' Проверка оплаты'),
                                            style: TextButton.styleFrom(
                                              backgroundColor: const Color(0xffb8d991),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                              foregroundColor: const Color(0xff0d360a),
                                              disabledForegroundColor: const Color(0xff0d360a),
                                              animationDuration: Duration.zero,
                                            ),
                                            onPressed: null,
                                          )
                                          : osagoProlongIsAccepted == true
                                            ? TextButton.icon(
                                              icon: const Icon(Icons.done_all),
                                              label: const Text('Полис успешно пролонгирован'),
                                              style: TextButton.styleFrom(
                                                backgroundColor: const Color(0xffc6e5a1),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                iconColor: const Color(0xff155211),
                                                foregroundColor: const Color(0xff155211),
                                                disabledForegroundColor: const Color(0xff155211),
                                                animationDuration: Duration.zero,
                                              ),
                                              onPressed: null,
                                            )
                                            : TextButton.icon(
                                              icon: const Icon(Icons.error_outline),
                                              label: Text('Подтверждение оплаты пока не получено. Если оплата была произведена, ${pleaseWaitResponseMessage.toLowerCase()}'),
                                              style: TextButton.styleFrom(
                                                backgroundColor: const Color(0xffc6e5a1),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                iconColor: const Color(0xff155211),
                                                foregroundColor: const Color(0xff155211),
                                                disabledForegroundColor: const Color(0xff155211),
                                                animationDuration: Duration.zero,
                                              ),
                                              onPressed: null,
                                            )

                                        : TextButton.icon(
                                          icon: const Icon(Icons.task_outlined),
                                          label: const Text('Оплатить'),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            foregroundColor: Colors.white,
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await goUrl(linkQr!, mode: LaunchMode.externalApplication);
                                          },
                                        )

                                    else if (osagoProlongDocId != null) TextButton.icon(
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text('Оформить'),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      onPressed: () async {
                                        setState(() => osagoProlongLegalIsFetching = true);
                                        await prolongOsagoLegal(osagoProlongDocId!);
                                        _fetchOsagoLegal(policy.docId);
                                      },
                                    )

                                  ],
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),

                      ListTile(
                        subtitle: const Text('Номер'),
                        title: Text(policy.docNumber),
                      ),
                      policy.objectName.isNotEmpty
                          ? ListTile(
                        subtitle: const Text('Объект страхования'),
                        title: Text(policy.objectName),
                      )
                          : const SizedBox.shrink(),
                      ListTile(
                        subtitle: const Text('Срок страхования'),
                        title: Text('с ${policy.dateS} по ${policy.dateE}'),
                      ),
                      policy.description.isNotEmpty
                          ? ListTile(
                        subtitle: Text(policy.description),
                        minVerticalPadding: 10,
                      )
                          : const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // посмотреть полис
                            policy.print
                              ? TextButton.icon(
                                icon: const Icon(Icons.article_outlined),
                                label: const Text('Посмотреть полис'),
                                style: getTextButtonStyle(),
                                onPressed: () async {
                                  final token = await Auth.token;
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PdfViewerPage(
                                          apiParams: ApiParams(
                                            'MobApp',
                                            'MP_polis_print',
                                            {
                                              'token': token,
                                              'Type': policy.type,
                                              'DocId': policy.docId,
                                            },
                                          )
                                        )
                                      )
                                    );
                                  }
                                },
                              )
                              : const SizedBox.shrink(),

                            // уведомить о дтп
                            policy.active && (policy.type == 'КАСКО' || policy.type == 'ОСАГО')
                              ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.gpp_maybe_outlined),
                                  label: const Text('Уведомить о ДТП'),
                                  style: getTextButtonStyle(),
                                  onPressed: () => context.go(
                                    '/polis_list/policy/accident_notification',
                                    extra: policy,
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),

                            // каско: внести изменения
                            policy.active && policy.type == 'КАСКО'
                              ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Внести изменения'),
                                  style: getTextButtonStyle(),
                                  onPressed: () => context.go(
                                    '/polis_list/policy/kasko_change',
                                    extra: policy,
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),

                            // пролонгировать: не осаго
                            if (policy.type != 'ОСАГО') Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton.icon(
                                icon: const Icon(Icons.update),
                                label: const Text('Пролонгировать'),
                                style: getTextButtonStyle(),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Пролонгация полиса'),
                                        content: SingleChildScrollView(
                                          child: Text('Отправить заявку на пролонгацию полиса ${policy.type} ${policy.docNumber}?'),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('Отмена'),
                                            onPressed: () => dialogContext.pop(),
                                          ),
                                          TextButton(
                                            child: const Text('Отправить'),
                                            onPressed: () {
                                              dialogContext.pop();
                                              setState(() => isLoading = true);
                                              _prolong();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            // пролонгировать: осаго
                            if (canOsagoProlong) Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: TextButton.icon(
                                  icon: const Icon(Icons.update),
                                  label: const Text('Пролонгировать'),
                                  style: getTextButtonStyle(),
                                  onPressed: () async {
                                    final String? osagoProlongReturn = await context.push('/polis_list/policy/osago_prolong', extra: policy);
                                    // вернулись нажав [пролонгировать без изменений]
                                    if (osagoProlongReturn == 'osagoProlong') {
                                      setState(() {
                                        canOsagoProlong = false;
                                        _fetchOsagoProlong(policy.docId);
                                      });
                                    }
                                    // вернулись нажав [пролонгировать с изменениями]
                                    else if (osagoProlongReturn == 'osagoProlongWithComment') {
                                      // todo: как-то добавить реквизит на бэке - что заявку отправлена
                                      setState(() {
                                        canOsagoProlong = false;
                                      });
                                    }
                                  }
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).toList(),
                );
              }
            }
          },
        ),
    );
  }

  _prolong({String? extraDescription}) async {
    final response = await sendClientRequest(
      policyType: widget.policy.type,
      docNumber: widget.policy.docNumber,
      extraDescription: extraDescription,
    );

    if (response) {
      if (mounted) {
        return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Успешно'),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              content: const Text('Ваша заявка на пролонгацию отправлена. С Вами свяжется оператор колл-центра.'),
              actions: [
                TextButton(
                  child: const Text('Хорошо'),
                  onPressed: () {
                    setState(() {
                      isLoading = false;
                    });
                    dialogContext.pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
    else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка отправки заявки. Попробуйте позже, либо воспользуйтесь формой "Обращение" в Личном кабинете.'),
          ),
        );
      }
    }
  }

}

Future<dynamic> loadCanOsagoProlong(String polisId) async {
  final body = {
    'token': await Auth.token,
    'DocId': polisId,
    'Method': 'can_osago_prolong',
  };
  final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_OSAGO', body)
  );
  return response;
}

Future<dynamic> prolongOsagoLegal(String polisId) async {
  final body = {
    'token': await Auth.token,
    'DocId': polisId,
    'Method': 'osago_prolong_legal',
  };
  final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_OSAGO', body)
  );
  return response;
}