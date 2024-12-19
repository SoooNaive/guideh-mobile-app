import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';


class PolisDmsProgramPage extends StatefulWidget {
  final String policyId;
  const PolisDmsProgramPage({super.key, required this.policyId});

  @override
  State<PolisDmsProgramPage> createState() => _PolisDmsProgramPageState();
}

class _PolisDmsProgramPageState extends State<PolisDmsProgramPage> {
  @override
  Widget build(BuildContext context) {
    final String polisId = widget.policyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Программа ДМС'), //police.DocNumber
      ),
      body: FutureBuilder(
        future: getDmsProgram(context, polisId),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Загрузка программы'),
                ],
              ),
            );
          }
          else {
            return SingleChildScrollView(
              child: Html(
                data: snapshot.data,
                style: {
                  '*': Style(fontSize: FontSize(16)),
                  'body': Style(padding: HtmlPaddings.all(10)),
                },
              ),
            );
          }
        }
      ),
    );
  }
}


Future<String> getDmsProgram(BuildContext context, polisId) async {
  final body = {
    'token': await Auth.token,
    'PolisId': polisId,
  };
  final response = await Http.mobApp(
    ApiParams('MobApp', 'MP_dms_polis_prog', body)
  );
  if (response['Error'] == 2) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['Message'] ?? 'Ошибка'),
        ),
      );
    }
    return '';
  }
  else if (response['Error'] == 1) {
    if (context.mounted) {
      Auth.logout(context, true);
    }
    return '';
  }
  else if (response['Error'] == 0) {
    return response['Data']['ProgramText'];
  }
  else {
    return '';
  }
}