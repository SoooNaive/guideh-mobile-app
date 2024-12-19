import 'package:guideh/pages/dms/models/policy_dms.dart';
import 'package:guideh/services/auth.dart';
import 'package:guideh/services/http.dart';

Future<List<PolicyDMS>> getPoliciesDMS() async {
  final response = await Http.mobApp(
      ApiParams('MobApp', 'MP_list_polisDMS', { 'token': await Auth.token })
  );

  List<PolicyDMS> policies = [];

  try {
    if (response['Error'] == 0) {
      policies.addAll((response['Data'] as List<dynamic>).map((item) {
        return PolicyDMS.fromJson(item);
      }));
    }
  } catch (e) {
    print(e);
  }

  return policies;
}