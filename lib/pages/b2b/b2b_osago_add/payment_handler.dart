import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/gai_api_request.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/services/pdf_viewer.dart';
import 'package:guideh/theme/theme.dart';

class PaymentIsSuccess extends StatefulWidget {
  final String contractId;

  const PaymentIsSuccess({
    super.key,
    required this.contractId,
  });

  @override
  State<PaymentIsSuccess> createState() => _PaymentIsSuccessState();
}

class _PaymentIsSuccessState extends State<PaymentIsSuccess> {

  bool policyIsReady = false;
  bool isError = false;

  Future<void> getPrintContract() async {
    Map<String, dynamic>? printContractResponse = await gaiApiRequest(
      '/printContract/',
      { 'contractId': widget.contractId, 'sendToClient': true },
      context
    );
    print(printContractResponse);
    if (printContractResponse?['status'] == 3) {
      setState(() => policyIsReady = true);
    }
    else if (mounted) {
      setState(() => isError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          showCloseIcon: true,
          closeIconColor: Colors.white,
          content: Text('Ошибка оплаты полиса'),
        ),
      );
    }
  }

  @override
  void initState() {
    getPrintContract();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: const Text('Полис ОСАГО'),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: !isError
            ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: secondaryColor,
                        width: 2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done, size: 35, color: secondaryColor),
                        SizedBox(width: 6),
                        Text(
                          'Оплата получена',
                          style: TextStyle(
                            fontSize: 20,
                            color: secondaryColor,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                    constraints: const BoxConstraints(minHeight: 165),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // color: secondaryLightColor,
                    ),
                    child: policyIsReady
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffd6efc9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 40,
                                ),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Полис успешно выпущен и отправлен на email страхователя.',
                                    style: TextStyle(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),
                          TextButton(
                            style: getTextButtonStyle(TextButtonStyle(
                              theme: 'primaryLight'
                            )),
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
                                          'Type': '',
                                          'DocId': widget.contractId,
                                        },
                                      )
                                    )
                                  )
                                );
                              }
                            },
                            child: const Text('Посмотреть полис'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            style: getTextButtonStyle(TextButtonStyle()),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/b2b_osago_list');
                              }
                            },
                            child: const Text('Вернуться в список полисов'),
                          ),
                        ],
                      )
                      : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xff444444),
                            strokeWidth: 1,
                          ),
                          SizedBox(height: 15),
                          Text('Создание полиса...'),
                        ],
                      )
                ),
              ],
            )
            : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ошибка'),
                  const SizedBox(height: 15),
                  TextButton(
                    style: getTextButtonStyle(TextButtonStyle()),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/b2b_osago_list');
                      }
                    },
                    child: const Text('Вернуться в список полисов'),
                  ),
                ],
              ),
            )
        ),
      ),

    );
  }
}
