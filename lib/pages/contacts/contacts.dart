import 'package:flutter/material.dart';
import 'contacts_list.dart';
import 'contacts_map.dart';


class Contacts extends StatelessWidget {
  const Contacts({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.primary,
            child: TabBar(
              indicatorWeight: 5,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              tabs: const [
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 10),
                  child: Text('Список')
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 10),
                  child: Text('Карта')
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                ContactsListPage(),
                ContactsMapPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}