import 'package:flutter/material.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/theme/theme.dart';
import 'models/branch.dart';
import 'branch_page_map.dart';


class BranchPage extends StatefulWidget {
  final Branch branch;
  const BranchPage({super.key, required this.branch});

  @override
  State<BranchPage> createState() => _BranchPageState();
}

class _BranchPageState extends State<BranchPage> {

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    return Scaffold(
      appBar: AppBar(
        title: Text(branch.cityName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: Flex(
                mainAxisAlignment: MainAxisAlignment.center,
                direction: Axis.horizontal,
                children: [
                  const SizedBox(
                    width: 57,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.pin_drop_outlined,
                        color: Colors.grey,
                      ),
                    )
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        '${branch.name}, ${branch.address}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: GestureDetector(
                onTap: () {
                  // makePhoneCall(branch.phone);
                  makePhoneCall(globalPhoneNumber);
                },
                child: Flex(
                  mainAxisAlignment: MainAxisAlignment.center,
                  direction: Axis.horizontal,
                  children: [
                    const SizedBox(
                      width: 57,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.call_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        // branch.phone_branch,
                        globalPhoneNumber,
                        style: const TextStyle(fontSize: 16)
                      )
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Ink(
                        padding: EdgeInsets.zero,
                        width: 40,
                        height: 40,
                        decoration: const ShapeDecoration(
                          color: primaryLightColor,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.call),
                          color: primaryColor,
                          onPressed: () {
                            // makePhoneCall(branch.phone);
                            makePhoneCall(globalPhoneNumber);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            (branch.email == '')
              ? const SizedBox.shrink()
              : const Divider(height: 1),
            (branch.email == '')
              ? const SizedBox.shrink()
              : Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: GestureDetector(
                onTap: () {
                  goEmail(branch.email);
                },
                child: Flex(
                  mainAxisAlignment: MainAxisAlignment.center,
                  direction: Axis.horizontal,
                  children: [
                    const SizedBox(
                      width: 57,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.email_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Text(
                          branch.email,
                          style: const TextStyle(fontSize: 16)
                        )
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Ink(
                        padding: EdgeInsets.zero,
                        width: 40,
                        height: 40,
                        decoration: const ShapeDecoration(
                          color: primaryLightColor,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.email_outlined),
                          color: primaryColor,
                          onPressed: () => goEmail(branch.email),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(
                Icons.access_time_outlined,
                color: Colors.grey,
              ),
              initiallyExpanded: true,
              textColor: Colors.black,
              title: Text(getWorkHoursString(branch)),
              subtitle: (branch.timeBreak != '')
                ? Text('Перерыв: ${branch.timeBreak.replaceAll('-', '–')}')
                : null,
              children: getWorkingHoursDays(branch, 0),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: Flex(
                mainAxisAlignment: MainAxisAlignment.center,
                direction: Axis.horizontal,
                children: [
                  const SizedBox(
                    width: 57,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                      ),
                    )
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        parseHtmlString(branch.type),
                        style: const TextStyle(fontSize: 16)
                      ),
                      // dense: true,
                      subtitle: (branch.note != '')
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(parseHtmlString(branch.note)
                          ),
                        )
                        : null,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 400,
              child: BranchPageMap(branch: branch),
            ),
          ],
        ),
      ),
    );
  }
}
