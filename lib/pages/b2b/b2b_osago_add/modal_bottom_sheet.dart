import 'package:flutter/material.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'gai_api_request.dart';
import 'payment_handler.dart';

class B2BOsagoModalBottomSheet extends StatefulWidget {
  final String calculationId;
  final Map<String, dynamic> calcResult;
  final Function(String contractId) uploadPhotos;

  const B2BOsagoModalBottomSheet({
    super.key,
    required this.calculationId,
    required this.calcResult,
    required this.uploadPhotos,
  });

  @override
  State<B2BOsagoModalBottomSheet> createState() => _B2BOsagoModalBottomSheetState();
}

class _B2BOsagoModalBottomSheetState extends State<B2BOsagoModalBottomSheet> with TickerProviderStateMixin {

  // слушатель лайфсайкла виджета
  late final AppLifecycleListener _listener;

  String? _contractId;
  bool isCreateContractLoading = false;
  bool waitingForBankReturn = false;
  bool? waitingForCreateContractReady;
  bool showWaitingMessage = false;
  String? rsaErrorMessage;
  final double progressIndicatorHeight = 5;
  late AnimationController _createContractLoadingController;

  @override
  void initState() {

    // контроллер анимации полоски загрузки оформления
    _createContractLoadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 37),
    )..addListener(() {
      setState(() {});
    });

    // при возврате → показываем ошибку оплаты
    _listener = AppLifecycleListener(onResume: _onResume);

    super.initState();
  }

  @override
  void dispose() {
    _listener.dispose();
    _createContractLoadingController.dispose();
    super.dispose();
  }

  void _onResume() async {
    if (waitingForBankReturn) {
      waitingForBankReturn = false;
      // подождём кэтч deepLink'а
      await Future.delayed(const Duration(seconds: 3));
      // не дождались, но есть contractId
      // если виджет уже попнулся (диплинк сработал) → выходим
      if (!mounted) return;
      if (_contractId != null) {
        // ручками проверим статус, ожидаем 09 (акцептирован РСА)
        Map<String, dynamic>? statusContractResponse = await gaiApiRequest(
            '/statusContract/',
            {'contractId': _contractId},
            context
        );
        print(statusContractResponse);
        if (statusContractResponse?['status'] == 3 &&
            statusContractResponse?['statusContract']['id'] == '09') {
          // успешная оплата (по statusContract)
          if (mounted) {
            Navigator.pop(context);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (context) => PaymentIsSuccess(contractId: _contractId!)),
            );
          }
          return;
        }
        // если не 09 → "ошибка оплаты"
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 5),
              showCloseIcon: true,
              closeIconColor: Colors.white,
              content: Text('Оплата не прошла'),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
            ),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final calcResult = widget.calcResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text('Стоимость полиса:'),
                ),
                Text('${calcResult['ratesOSAGO']['premium']} руб.', style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 20),
                if (isCreateContractLoading) Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffefdfcf),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Отправляем данные в РСА, подождите...'),
                  ),
                )
                else if (showWaitingMessage) Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 10
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffefdfcf),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Ответ от РСА ещё не поступил. Нажмите "Проверить" через минуту, либо зайдите позже в список договоров.'),
                  ),
                )
                else if (rsaErrorMessage != null) Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffefcfcf),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Запрос отклонён РСА. Причина: $rsaErrorMessage'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                        onPressed: isCreateContractLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                    ),
                    if (rsaErrorMessage == null) const SizedBox(width: 10),
                    if (rsaErrorMessage == null) Expanded(
                      child: TextButton(
                        style: getTextButtonStyle(TextButtonStyle(theme: 'primary')),
                        onPressed: isCreateContractLoading
                          ? null
                          : () async {
                            setState(() {
                              showWaitingMessage = false;
                              rsaErrorMessage = null;
                              isCreateContractLoading = true;
                            });
                            _createContractLoadingController.forward();
                            // первый запрос на оформление
                            if (waitingForCreateContractReady == null) {
                              if (await createContract() == false) {
                                setState(() => isCreateContractLoading = false);
                              }
                              return;
                            }
                            // уже ожидаем оформление
                            if (await createContractGet() == false) {
                              setState(() => isCreateContractLoading = false);
                            }
                        },
                        child: isCreateContractLoading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : waitingForCreateContractReady == false
                            ? const Text('Проверить')
                            : const Text('Оформить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isCreateContractLoading) LinearProgressIndicator(
          value: _createContractLoadingController.value,
          minHeight: progressIndicatorHeight,
          color: secondaryColor,
          backgroundColor: primaryLightColor,
        )
        else const SizedBox(height: 5),
      ],
    );
  }

  // отправляем на оформление
  Future<bool> createContract() async {
    final createContractResponse = await gaiApiRequest('/createContract/', {
      'calculationId': widget.calculationId
    }, context);
    print(createContractResponse);

    final String? contractId = createContractResponse?['contractId'];
    setState(() => _contractId = contractId);
    if (contractId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка получения проекта договора')),
        );
      }
      return false;
    }

    return await createContractGet();
  }

  // гет-запрос в createContract
  Future<bool> createContractGet() async {
    showWaitingMessage = false;

    if (_contractId == null) {
      print('Ошибка при get-запросе в createContract: нет contractId в стейте');
      return false;
    }

    print('go get createContract!');

    // get запросы в createContract
    // подгоняем под время анимации полоски _createContractLoadingController
    int counter = 7;
    while (counter > 0 || waitingForCreateContractReady == true) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      final createContractGetResponse =
        await gaiApiRequest('/createContract/?contractId=$_contractId', null, context);
      print(createContractGetResponse);
      final status = createContractGetResponse?['status'];

      // успех
      if (status == 3) {
        final String? contractNumber = createContractGetResponse?['contractNumber'];
        if (contractNumber != null) {
          // получили номер полиса
          // грузим фотки
          await widget.uploadPhotos(_contractId!);
          // запрос ссылки на оплату → переход
          await createPay(_contractId!);
          waitingForCreateContractReady = false;
          return true;
        }
        else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка получения номера договора'), showCloseIcon: true),
          );
        }
        counter = 1;
      }

      // ошибка РСА
      else if (createContractGetResponse?['error'] is List && createContractGetResponse?['error'].isNotEmpty) {
        _createContractLoadingController.stop();
        _createContractLoadingController.reset();
        setState(() {
          waitingForCreateContractReady = false;
          showWaitingMessage = false;
          rsaErrorMessage = createContractGetResponse?['error'][0]['Name'];
        });
        counter = 1;
        return false;
      }
      counter--;
    }

    // не дождались
    _createContractLoadingController.stop();
    _createContractLoadingController.reset();
    setState(() {
      waitingForCreateContractReady = false;
      showWaitingMessage = true;
    });
    return false;
  }

  // запрос ссылки на оплату
  Future<bool> createPay(String contractId) async {
    final createPayResponse = await gaiApiRequest('/createPay/', {
      'contractId': [contractId],
      'successUrl': 'https://guidehins.ru/app/?contract_id=$contractId&tinkoff_return=1',
      'failUrl': 'https://guidehins.ru/app/?contract_id=$contractId&tinkoff_return=0',
    }, context);
    print(createPayResponse);
    final status = createPayResponse?['status'];
    final String? linkPay = createPayResponse?['LinkPay'];
    if (status == 3 && linkPay != null) {
      try {
        setState(() => waitingForBankReturn = true);
        _createContractLoadingController.stop();
        _createContractLoadingController.value = 1;
        goUrl(linkPay, mode: LaunchMode.externalApplication);
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось перейти по ссылке на оплату. Попробуйте позже.'),
            ),
          );
        }
        return false;
      }
    }
    else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка получения ссылки на оплату.'),
            showCloseIcon: true,
          ),
        );
      }
      return false;
    }
  }

}
