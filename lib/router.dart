import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import 'package:guideh/layout/scaffold/scaffold.dart';
import 'package:guideh/pages/b2b/b2b.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/b2b_osago_add.dart';
import 'package:guideh/pages/b2b/b2b_osago_add/payment_handler.dart';
import 'package:guideh/pages/b2b/b2b_osago_list.dart';
import 'package:guideh/pages/checkup_house/models.dart';
import 'package:guideh/pages/checkup_kasko/checkup_kasko.dart';
import 'package:guideh/pages/checkup_kasko/done.dart';
import 'package:guideh/pages/checkup_kasko/start.dart';
import 'package:guideh/pages/dms/history_case.dart';
import 'package:guideh/pages/dms/letters_of_guarantee/guarantee_letters.dart';
import 'package:guideh/pages/dms/models/policy_dms.dart';
import 'package:guideh/pages/polis/kasko_change_drivers_add.dart';
import 'package:guideh/pages/polis/osago_prolong.dart';

import 'package:guideh/pages/start/login.dart';
import 'package:guideh/pages/start/recover_password.dart';
import 'package:guideh/pages/start/signup.dart';
import 'package:guideh/pages/start/start.dart';
import 'package:guideh/pages/contacts/branch_page.dart';
import 'package:guideh/pages/contacts/contacts.dart';
import 'package:guideh/pages/dms/lpu.dart';
import 'package:guideh/pages/dms/add_req.dart';
import 'package:guideh/pages/dms/dms.dart';
import 'package:guideh/pages/dms/history.dart';
import 'package:guideh/pages/dms/program.dart';
import 'package:guideh/pages/polis/accident_notification.dart';
import 'package:guideh/pages/polis/polis_detail.dart';
import 'package:guideh/pages/polis/polis_list.dart';
import 'package:guideh/pages/polis/kasko_change.dart';
import 'package:guideh/pages/polis/kasko_change_drivers.dart';
import 'package:guideh/pages/sos/sos.dart';

import 'package:guideh/pages/checkup_house/start.dart';
import 'package:guideh/pages/checkup_house/checkup_house.dart';

import 'package:guideh/services/auth.dart';
import 'package:guideh/pages/polis/models/policy.dart';
import 'package:guideh/pages/contacts/models/branch.dart';
import 'package:guideh/pages/dms/models/lpu.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

bool _splashScreenIsClosed = false;

// отключаем splash-screen с фэйк задержкой
redirectWithDelay(String? value) async {
  if (!_splashScreenIsClosed) {
    _splashScreenIsClosed = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      FlutterNativeSplash.remove();
      return value;
    });

  }
  return value;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/polis_list',
  redirect: (BuildContext context, GoRouterState state) async {
    // если это не /start
    if (state.uri.toString().startsWith('/start')) {
      return await redirectWithDelay(null);
    }
    // проверяем залогинен ли юзер
    return await Auth.checkAuth(context) ? await redirectWithDelay(null) : await redirectWithDelay('/start');
  },
  routes: <RouteBase>[

    // start
    GoRoute(
      path: '/start',
      builder: (context, state) => const StartScreen(),
      routes: [
        // login
        GoRoute(
          name: 'login',
          path: 'login',
          builder: (context, state) => LoginScreen(
            isPasswordRecovered: state.uri.queryParameters['isPasswordRecovered'],
          ),
          routes: [
            GoRoute(
              name: 'recoverpass',
              path: 'recoverpass',
              builder: (context, state) => RecoverpassScreen(
                  phone: state.uri.queryParameters['phone']!
              ),
            ),
          ],
        ),
        // signup
        GoRoute(
          path: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        // home
      ],
    ),

    // shell with bottom menu
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return const AppScaffold();
      },
      routes: [
        // B2B
        GoRoute(
          name: 'b2b',
          path: '/b2b',
          builder: (context, state) => const B2BPage(),
          routes: [
            // b2b_osago_list
            GoRoute(
              name: 'b2b_osago_list',
              path: 'osago_list',
              builder: (context, state) => const B2BOsagoList(),
              parentNavigatorKey: _rootNavigatorKey,
              routes: [
                // b2b_osago_add
                GoRoute(
                  name: 'b2b_osago_add',
                  path: 'add',
                  builder: (context, state) => const B2BOsagoAdd(),
                  parentNavigatorKey: _rootNavigatorKey,
                ),
              ],
            ),
          ],
        ),
        // polis_list
        GoRoute(
          name: 'polis_list',
          path: '/polis_list',
          builder: (context, state) => PoliciesList(
            updateListPolis: state.uri.queryParameters['updateListPolis'] == 'true'
          ),
          routes: [
            // policy
            GoRoute(
              path: 'policy',
              builder: (context, state) => DetailPage(
                policy: state.extra as Policy,
              ),
              parentNavigatorKey: _rootNavigatorKey,
              routes: [
                // accident_notification
                GoRoute(
                  name: 'accident_notification',
                  path: 'accident_notification',
                  builder: (context, state) => AccidentNotificationPage(
                    policy: state.extra as Policy,
                  ),
                  parentNavigatorKey: _rootNavigatorKey,
                ),
                // kasko_change
                GoRoute(
                  name: 'kasko_change',
                  path: 'kasko_change',
                  builder: (context, state) => KaskoChangePage(
                    policy: state.extra as Policy,
                  ),
                  parentNavigatorKey: _rootNavigatorKey,
                  routes: [
                    // drivers
                    GoRoute(
                      name: 'kasko_change_drivers',
                      path: 'drivers',
                      builder: (context, state) => KaskoChangeDriversPage(
                        policy: state.extra as Policy,
                      ),
                      parentNavigatorKey: _rootNavigatorKey,
                      routes: [
                        // add driver
                        GoRoute(
                          name: 'kasko_change_drivers_add',
                          path: 'add',
                          builder: (context, state) => const KaskoChangeDriversAddPage(),
                          parentNavigatorKey: _rootNavigatorKey,
                        ),
                      ],
                    ),
                  ],
                ),
                // osago_prolong
                GoRoute(
                  name: 'osago_prolong',
                  path: 'osago_prolong',
                  builder: (context, state) => OsagoProlongPage(
                    policy: state.extra as Policy,
                  ),
                  parentNavigatorKey: _rootNavigatorKey,
                ),
              ],
            ),
          ],
        ),
        // dms
        GoRoute(
          path: '/dms',
          builder: (context, state) => DMS(
            policiesDMS: state.extra as List<PolicyDMS>?,
          ),
          routes: [
            // lpu
            GoRoute(
              name: 'dms_lpu',
              path: 'lpu',
              builder: (context, state) => DmsLpuPage(
                policyId: state.uri.queryParameters['policy_id']!,
              ),
              parentNavigatorKey: _rootNavigatorKey,
              routes: [
                GoRoute(
                  name: 'dms_lpu_add_req',
                  path: 'lpu_add_req',
                  builder: (context, state) => AddReq(
                    policyId: state.uri.queryParameters['policy_id']!,
                    lpu: state.extra as DmsLpu?,
                  ),
                  parentNavigatorKey: _rootNavigatorKey,
                ),
              ],
            ),
            // history
            GoRoute(
              path: 'history',
              builder: (context, state) => const History(),
              parentNavigatorKey: _rootNavigatorKey,
              routes: [
                GoRoute(
                  name: 'history_case',
                  path: 'case',
                  builder: (context, state) => HistoryCase(
                    historyCaseId: state.uri.queryParameters['history_case_id']!,
                  ),
                  parentNavigatorKey: _rootNavigatorKey,
                ),
              ],
            ),
            // add_req
            GoRoute(
              name: 'dms_add_req',
              path: 'add_req',
              builder: (context, state) => AddReq(
                policyId: state.uri.queryParameters['policy_id']!,
              ),
              parentNavigatorKey: _rootNavigatorKey,
            ),
            // program
            GoRoute(
              name: 'dms_program',
              path: 'program',
              builder: (context, state) => PolisDmsProgramPage(
                policyId: state.uri.queryParameters['policy_id']!,
              ),
              parentNavigatorKey: _rootNavigatorKey,
            ),
            // letters_of_guarantee
            GoRoute(
              name: 'letters_of_guarantee',
              path: 'letters_of_guarantee',
              builder: (context, state) => GuaranteeLettersPage(
                policyId: state.uri.queryParameters['policy_id']!,
                policyNumber: state.uri.queryParameters['policy_number']!,
              ),
              parentNavigatorKey: _rootNavigatorKey,
            ),
          ],
        ),
        // sos
        GoRoute(
          path: '/sos',
          builder: (context, state) => const SosPage(),
        ),
        // contacts
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const Contacts(),
          routes: [
            // branch
            GoRoute(
              path: 'branch',
              builder: (context, state) => BranchPage(
                branch: state.extra as Branch,
              ),
              parentNavigatorKey: _rootNavigatorKey,
            ),
          ],
        ),
      ],
    ),

    // from deep links
    GoRoute(
      name: 'tinkoff_return',
      path: '/tinkoff_return',
      builder: (context, state) {
        Map<String, String> queryParameters = state.extra as Map<String, String>;
        return PaymentIsSuccess(contractId: queryParameters['contract_id']!);
      },
    ),
    GoRoute(
      name: 'checkup_house_start',
      path: '/checkup_house_start',
      builder: (context, state) {
        Map<String, String> queryParameters = state.extra as Map<String, String>;
        return CheckupHouseStart(
          queryParameters: queryParameters
        );
      },
    ),
    GoRoute(
      name: 'checkup_house',
      path: '/checkup_house',
      builder: (context, state) => CheckupHouse(
        parentId: state.uri.queryParameters['parentId'],
        httpCaseObjects: state.extra as List<CheckupHouseCaseObject>,
      ),
    ),
    GoRoute(
      name: 'checkup_kasko_start',
      path: '/checkup_kasko_start',
      builder: (context, state) {
        Map<String, String> queryParameters = state.extra as Map<String, String>;
        return CheckupKaskoStart(
          queryParameters: queryParameters
        );
      },
    ),
    GoRoute(
      name: 'checkup_kasko',
      path: '/checkup_kasko',
      builder: (context, state) => CheckupKasko(
        parentId: state.uri.queryParameters['parentId'],
        parentIdType: state.uri.queryParameters['parentIdType'],
        stepName: state.uri.queryParameters['stepName'],
        checkupData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      name: 'checkup_kasko_done',
      path: '/checkup_kasko_done',
      builder: (context, state) => const CheckupKaskoDone(),
    ),

  ],

  errorPageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    child: Text(state.error.toString()),
  ),

);
