import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/layout/my_title.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/pages/polis/send_client_request.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:intl/intl.dart';

class OsagoProlongPage extends StatefulWidget {
  final Policy policy;
  const OsagoProlongPage({super.key, required this.policy});

  @override
  State<OsagoProlongPage> createState() => _OsagoProlongPageState();
}

class _OsagoProlongPageState extends State<OsagoProlongPage> {

  bool isLoading = false;

  late Map<String, dynamic> osagoProlongCase;
  late Future<void> _initDataLoad;
  Future<void> _initData() async {
    osagoProlongCase = await loadOsagoProlongCase(widget.policy.docId);
  }

  late NavigatorState _navigator;
  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _initDataLoad = _initData();
  }

  final prolongOsagoCommentForm = GlobalKey<FormState>();
  final TextEditingController _prolongOsagoComment = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пролонгация ОСАГО'),
        centerTitle: true,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : FutureBuilder(
          future: _initDataLoad,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active: {
                return const Center(child: CircularProgressIndicator());
              }
              case ConnectionState.done: {
                final Map<String, dynamic>? policyData = osagoProlongCase['PolisData'];
                DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                final String dateBegin = DateFormat('dd.MM.yyyy').format(dateFormat.parse(policyData?['DateBeg']));
                final String dateEnd = DateFormat('dd.MM.yyyy').format(dateFormat.parse(policyData?['DateEnd']));
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [

                        MyTitle('Полис ${widget.policy.docNumber}'),

                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: const BoxDecoration(
                              color: Color(0xffefe6c8),
                              borderRadius: BorderRadius.all(Radius.circular(5))
                          ),
                          child: const Text(
                              'Проверьте данные нового полиса',
                              style: TextStyle(
                                  color: Color(0xff78610a)
                              )
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextFormField(
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Объект страхования',
                            labelStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                          readOnly: true,
                          initialValue: policyData?['Car']['Name'] ?? '–',
                          minLines: 1,
                          maxLines: 3,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Страхователь',
                            labelStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                          readOnly: true,
                          initialValue: policyData?['Insurer'] ?? '–',
                          minLines: 1,
                          maxLines: 2,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Собственник',
                            labelStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                          readOnly: true,
                          initialValue: policyData?['Owner'] ?? '–',
                          minLines: 1,
                          maxLines: 2,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Сроки страхования',
                            labelStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                          readOnly: true,
                          initialValue: '$dateBegin – $dateEnd',
                          minLines: 1,
                          maxLines: 2,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: 'Водители',
                            labelStyle: TextStyle(color: Colors.grey),
                            counterText: '',
                          ),
                          readOnly: true,
                          initialValue: policyData?['Driver'].map((driver) => driver['Name']).join('\n'),
                          minLines: 1,
                          maxLines: 6,
                        ),

                        const SizedBox(height: 20),

                        TextButton.icon(
                          icon: const Icon(Icons.done),
                          label: const Text(
                            'Пролонгировать без изменений',
                            textAlign: TextAlign.center,
                          ),
                          style: getTextButtonStyle(),
                          onPressed: () async {
                            setState(() => isLoading = true);
                            await _prolongOsago();
                            _navigator.pop('osagoProlong');
                          },
                        ),

                        const SizedBox(height: 10),

                        TextButton.icon(
                          icon: const Icon(Icons.edit_note),
                          label: const Text(
                            'Внести изменения',
                            textAlign: TextAlign.center,
                          ),
                          style: getTextButtonStyle(TextButtonStyle(theme: 'primaryLight')),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  titlePadding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 16
                                  ),
                                  title: const Text('Опишите изменения'),
                                  insetPadding: const EdgeInsets.all(16),
                                  content: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: SingleChildScrollView(
                                      child: Form(
                                        key: prolongOsagoCommentForm,
                                        child: TextFormField(
                                          controller: _prolongOsagoComment,
                                          minLines: 4,
                                          maxLines: null,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(5)
                                              )
                                            ),
                                            labelText: 'Введите текст',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Введите текст';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Отмена'),
                                      onPressed: () => dialogContext.pop(),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (prolongOsagoCommentForm.currentState!.validate()) {
                                          dialogContext.pop();
                                          setState(() {
                                            isLoading = true;
                                          });
                                          final bool prolongResult = await _prolongOsagoWithComment(
                                            _prolongOsagoComment.text,
                                          );
                                          if (prolongResult) {
                                            if (_navigator.mounted) {
                                              print('1.5');
                                              ScaffoldMessenger.of(_navigator.context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Ваша заявка на пролонгацию отправлена. С Вами свяжется оператор колл-центра.'),
                                                  duration: Duration(seconds: 10),
                                                ),
                                              );
                                              print('2');
                                              _navigator.pop('osagoProlongWithComment');
                                            }
                                          }
                                          else {
                                            if (_navigator.mounted) {
                                              ScaffoldMessenger.of(_navigator.context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Ошибка отправки заявки. Попробуйте позже, либо воспользуйтесь формой "Обращение" в Личном кабинете.'),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: primaryLightColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: const Text('Пролонгировать'),
                                    ),
                                  ],
                                  actionsAlignment: MainAxisAlignment.spaceBetween,
                                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                );
                              },
                            );
                          },
                        ),

                      ],
                    ),
                  ),
                );
              }
            }
          }
      ),
    );
  }

  _prolongOsago() async {
    final body = {
      'token': await Auth.token,
      'DocId': widget.policy.docId,
      'Method': 'osago_prolong',
    };
    final response = await Http.mobApp(
        ApiParams('MobApp', 'MP_OSAGO', body)
    );
    return response;
  }

  // пролонгация с изменениями → через обращения клиента
  Future<bool> _prolongOsagoWithComment(String comment) async {
    return await sendClientRequest(
      policyType: widget.policy.type,
      docNumber: widget.policy.docNumber,
      extraDescription: comment,
    );
  }

}

Future<Map<String, dynamic>> loadOsagoProlongCase(String polisId) async {
  final body = {
    'token': await Auth.token,
    'DocId': polisId,
    'Method': 'osago_prolong_case',
  };
  final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_OSAGO', body)
  );
  return response;
}
