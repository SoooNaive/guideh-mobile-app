import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guideh/layout/scaffold/scaffold_bloc.dart' as scaffold_bloc;
import 'package:guideh/layout/scaffold/scaffold_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:guideh/pages/b2b/b2b.dart';
import 'package:guideh/pages/polis/polis_list.dart';
import 'package:guideh/pages/dms/dms.dart';
import 'package:guideh/pages/sos/sos.dart';
import 'package:guideh/pages/contacts/contacts.dart';
import 'package:guideh/layout/drawer_menu.dart';


class Tab {
  final String title;
  final String name;
  final Widget widget;
  final Widget icon;

  Tab(this.title, this.name, this.widget, this.icon);
}


class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  List<Tab> tabs = [
    Tab(
      'Полисы',
      'polis_list',
      const PoliciesList(),
      const Icon(Icons.verified_user),
    ),
    Tab(
      'ДМС',
      'dms',
      const DMS(),
      const Icon(Icons.medical_services),
    ),
    Tab(
      'События',
      'sos',
      const SosPage(),
      const Icon(Icons.offline_bolt),
    ),
    Tab(
      'Контакты',
      'contacts',
      const Contacts(),
      const Icon(Icons.place),
    ),
  ];
  late int _selectedTabIndex;
  late Tab _selectedTab;
  late ScaffoldBloc scaffoldBloc;
  bool userIsAgent = false;

  void _loadAgentTab() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    userIsAgent = preferences.getString('agentId') != null;
    // если юзер агент - покажем вкладку B2B
    if (userIsAgent) {
      setState(() {
        tabs.insert(0, Tab(
          'B2B',
          'b2b',
          const B2BPage(),
          const Icon(Icons.insert_chart),
        ));
      });
    }
  }

  Future<void> _loadPermissions() async {
    final PermissionStatus statusNotification = await Permission.notification.request();
    scaffoldBloc.add(ScaffoldUpdateNotificationsPermissionStatusEvent(statusNotification));

    // todo
    // final PermissionStatus statusStorage = await Permission.storage.request();
    // scaffoldBloc.add(ScaffoldUpdateStoragePermissionStatusEvent(statusStorage));
  }


  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
    _selectedTab = tabs.elementAt(_selectedTabIndex);
    scaffoldBloc = BlocProvider.of<scaffold_bloc.ScaffoldBloc>(context);
    _loadPermissions();
    _loadAgentTab();
  }

  @override
  Widget build(BuildContext context) {

    final GlobalKey<DrawerMenuState> drawerState = GlobalKey();

    return BlocBuilder<scaffold_bloc.ScaffoldBloc, scaffold_bloc.ScaffoldState>(
      bloc: scaffoldBloc,
      builder: (context, state) {

        _selectedTabIndex = state.selectedTabIndex;
        _selectedTab = tabs.elementAt(_selectedTabIndex);

        return Scaffold(

          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              onPressed: () {},
              icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
            ),
            title: Text(_selectedTab.title),
            elevation: _selectedTab.name != 'contacts' ? 4 : 0,
          ),

          body: PageView(
            controller: scaffoldBloc.state.pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              tabs.length,
              (index) => tabs[index].widget,
            ),
          ),

          bottomNavigationBar: BottomNavigationBar(
            items: List.generate(
              tabs.length, (index) =>
                BottomNavigationBarItem(
                  icon: tabs[index].icon,
                  label: tabs[index].title,
                ),
            ),
            unselectedItemColor: const Color(0xFF444455),
            currentIndex: _selectedTabIndex,
            selectedItemColor: Colors.red,
            showUnselectedLabels: true,
            onTap: (selectedPageIndex) {
              scaffoldBloc.add(scaffold_bloc.ScaffoldGoToTabEvent(selectedPageIndex));
            },
          ),

          endDrawer: DrawerMenu(key: drawerState),

        );
      },
    );
  }

}