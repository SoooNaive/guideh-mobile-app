import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/checkup_house/functions.dart';
import 'package:guideh/pages/checkup_house/models.dart';

Widget checkupHouseStepBuilder(
    BuildContext context,
    CheckupHouseStepContent stepContent,
  ) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.format_list_numbered),
        onPressed: () {
          context.pop();
          // context.goNamed(
          //   'checkup_house',
          //   // todo
          //   // queryParameters: {
          //   //   'stepIndex': stepIndex.toString(),
          //   // }
          // );
        },
      ),
      title: stepContent.title,
      centerTitle: true,
    ),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: stepContent.content,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(80),
                spreadRadius: 2,
                blurRadius: 6,
              ),
            ],
          ),
          child: stepContent.bottom,
        ),
      ],
    ),
  );
}

Widget getStepScaffoldTitle(bool isBuildingStep, int stepIndex, String? stepParent) {
  String text = '';
  if (isBuildingStep) text += stepParent ?? '';
  text += isBuildingStep ? ': шаг ' : 'Шаг ';
  text += '${stepIndex + 1} из ${isBuildingStep ? stepsBuilding.length : stepsMain.length}';
  return Text(text, style: TextStyle(fontSize: isBuildingStep ? 14 : 18));
}