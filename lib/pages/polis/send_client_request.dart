import 'package:guideh/services/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> sendClientRequest({
  required String policyType,
  required String docNumber,
  String? extraDescription,
}) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();

  if (extraDescription != null) {
    extraDescription = '\n\n$extraDescription';
  }

  final response = await Http.mobApp(
    ApiParams('ClientsRequest', 'Req_save_b2b', {
      'Resource': 'Мобильное приложение',
      'Theme': 'Пролонгация договора страхования',
      'Name': preferences.getString('userName') ?? '',
      'Phone': preferences.getString('phone') ?? '',
      'Email': '',
      'IP': '',
      'Description': 'Заявка на пролонгацию договора $policyType $docNumber ${extraDescription ?? ''}',
    })
  );

  return response['Status'] == 'ok';
}