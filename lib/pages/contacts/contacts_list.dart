import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api_data.dart';
import 'models/branch.dart';
import 'models/branch_city.dart';

class ContactsListPage extends StatefulWidget {
  const ContactsListPage({super.key});

  @override
  State<ContactsListPage> createState() => _ContactsListPageState();
}

class _ContactsListPageState extends State<ContactsListPage> with AutomaticKeepAliveClientMixin<ContactsListPage> {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: ApiData().getBranches(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {

        if (snapshot.data == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text('Загрузка контактов'),
              ],
            ),
          );
        }
        else {

          // группируем по городам
          List<BranchCity> cities = [];
          final List<String> loadedCityIds = [];

          for (var i = 0; i < snapshot.data.length; i++) {
            final Branch branchItem = snapshot.data[i];
            if (!loadedCityIds.contains(branchItem.cityId)) {
              cities.add(BranchCity(
                index: i,
                id: branchItem.cityId,
                name: branchItem.cityName,
                isExpanded: false,
                branches: snapshot.data.where((Branch branch) => branch.cityId == branchItem.cityId).toList(),
              ));
            }
            loadedCityIds.add(branchItem.cityId);
          }

          return ExpandListView(cities: cities);

        }
      }
    );
  }
}


class ExpandListView extends StatelessWidget {
  final List<BranchCity> cities;

  const ExpandListView({super.key, required this.cities});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: cities.length,
      itemBuilder: (context, index) => ExpandTileCard(
        id: cities[index].id,
        name: cities[index].name,
        branches: cities[index].branches,
      ),
      separatorBuilder: (BuildContext context, int index) => const Divider(
        height: 0,
      ),
    );
  }
}

class ExpandTileCard extends StatelessWidget {
  final String id;
  final String name;
  final List<Branch> branches;

  const ExpandTileCard({
    super.key,
    required this.id,
    required this.name,
    required this.branches
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(name),
      backgroundColor: Colors.white,
      children: List.generate(branches.length, (index) {
        final branchInCity = branches[index];
        return Column(
          children: <Widget>[
            const Divider(
              height: 10,
            ),
            ListTile(
              title: Text(branchInCity.name),
              subtitle: Text(branchInCity.address),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.go(
                '/contacts/branch',
                extra: branchInCity,
              ),
            ),
          ],
        );
      }),
    );
  }
}
