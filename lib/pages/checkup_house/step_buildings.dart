import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/theme/theme.dart';

import 'functions.dart';
import 'models.dart';

class StepBuildings extends StatefulWidget {
  final List<CheckupHouseCaseObject> caseObjects;
  final List<CheckupHouseCaseObject> caseBuildings;
  final Function(StepData previousStep, CheckupHouseCaseObject previousCaseObject) goToStep;
  const StepBuildings({
    super.key,
    required this.caseObjects,
    required this.caseBuildings,
    required this.goToStep,
  });

  @override
  State<StepBuildings> createState() => _StepBuildingsState();
}

class _StepBuildingsState extends State<StepBuildings> {

  int? expandedBuildingIndex;
  int? expandedBuildingStepIndex;

  late TextEditingController _addBuildingController;
  final addBuildingFormKey = GlobalKey<FormState>();

  // названия всех строений, для валидации
  List<String> buildingsNames = [];

  @override
  void initState() {
    super.initState();
    _addBuildingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    // print('build buildings stepper');

    for (CheckupHouseCaseObject building in widget.caseBuildings) {
      if (building.name != null) buildingsNames.add(building.name!);
    }

    return Column(
      children: [
        if (widget.caseBuildings.isNotEmpty) Column(
          children: [
            const Divider(height: 0.5),
            Container(
              decoration: const BoxDecoration(color: Color(0xFFB5D0EC)),

              // аккордеон строений
              child: ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  _openBuildingPanel(index);
                },
                expandedHeaderPadding: EdgeInsets.zero,
                elevation: 4,
                children: widget.caseBuildings.mapIndexed((
                    int buildingIndex,
                    CheckupHouseCaseObject building
                    ) {

                  // building'и – это объекты, у которых object.parent == 'buildings'
                  // типа { "Type": "mainBuilding", "Parent": "buildings", "Name": "Жилой дом" }

                  final bool invalidOrCheckFalse = building.invalid == true || building.check == false;

                  // панель строения
                  return ExpansionPanel(
                    canTapOnHeader: true,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        // иконка строения
                        leading: ClipOval(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            color: isExpanded
                              ? invalidOrCheckFalse
                                ? Colors.red
                                : secondaryColor
                              : invalidOrCheckFalse
                                ? const Color(0x24ff0000)
                                : secondaryLightColor,
                            child: Icon(
                              Icons.home,
                              size: 18,
                              color: isExpanded
                                ? invalidOrCheckFalse
                                  ? Colors.white
                                  : secondaryLightColor
                                : invalidOrCheckFalse
                                  ? Colors.red
                                  : secondaryColor,
                            ),
                          ),
                        ),
                        iconColor: secondaryColor,
                        // название строения
                        title: Text(
                          building.name ?? 'Строение без названия',
                          style: TextStyle(
                            fontWeight: isExpanded ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        textColor: secondaryDarkColor,
                        horizontalTitleGap: 2,
                      );
                    },
                    body: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFDAE8F5),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),

                      // аккордеон шагов строения
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15)
                        ),
                        child: ExpansionPanelList(
                          expansionCallback: (int index, bool isExpanded) {
                            _toggleBuildingStepPanel(index == expandedBuildingStepIndex
                              ? null
                              : index
                            );
                          },
                          expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 5),
                          dividerColor: primaryLightColor,
                          elevation: 0,
                          children: stepsBuilding.mapIndexed((int buildingStepIndex, step) {

                            // ищем caseObject ШАГА: { "Type": "locking", "Parent": "Жилой дом" }

                            final CheckupHouseCaseObject caseObject = widget.caseObjects.firstWhere(
                              (object) => object.parent == building.name && object.type == step.type,
                              // если нет такого caseObject → добавим его в caseObjects
                              orElse: () {
                                final newCaseObject = CheckupHouseCaseObject(
                                  type: step.type,
                                  parent: building.name,
                                  photos: [],
                                  photosPath: [],
                                );
                                widget.caseObjects.add(newCaseObject);
                                return newCaseObject;
                              }
                            );

                            final int photosCount = caseObject.photosCount;
                            final bool invalidOrCheckFalse = caseObject.invalid == true || caseObject.check == false;

                            // панель шага строения
                            return ExpansionPanel(
                              canTapOnHeader: true,
                              headerBuilder: (BuildContext context, bool isExpanded) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: ListTile(
                                    visualDensity: VisualDensity.compact,
                                    minVerticalPadding: 12,

                                    // номер шага
                                    leading: Container(
                                      alignment: Alignment.center,
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isExpanded
                                          ? invalidOrCheckFalse
                                            ? Colors.red
                                            : secondaryColor
                                          : invalidOrCheckFalse
                                            ? const Color(0x24ff0000)
                                            : secondaryLightColor,
                                      ),
                                      child: Text(
                                        (buildingStepIndex + 1).toString(),
                                        style: TextStyle(
                                          color: isExpanded
                                            ? Colors.white
                                            : invalidOrCheckFalse
                                              ? Colors.red
                                              : secondaryDarkColor,
                                          fontWeight: isExpanded ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                      ),
                                    ),

                                    // название шага
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.title,
                                          style: TextStyle(
                                            color: secondaryDarkColor,
                                            fontSize: 15,
                                            fontWeight: isExpanded ? FontWeight.w500 : FontWeight.normal
                                          )
                                        ),
                                        if (photosCount > 0 || caseObject.invalid == true) const SizedBox(height: 6),
                                        if (photosCount > 0 || caseObject.invalid == true) Wrap(
                                          spacing: 3,
                                          runSpacing: 3,
                                          children: [
                                            ...List.generate(photosCount, (i) => i + 1).map((el) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration: const BoxDecoration(color: Color(0xffd6d6e0)),
                                                ),
                                              );
                                            }),
                                            if (step.minPhotos != null && photosCount < step.minPhotos!) Padding(
                                              padding: photosCount > 0 ? const EdgeInsets.only(left: 8) : EdgeInsets.zero,
                                              child: Text(
                                                  'Минимум ${step.minPhotos} фото',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    height: 0.9,
                                                    color: caseObject.invalid == true ? Colors.red : Colors.grey,
                                                  )
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    horizontalTitleGap: 8,
                                  ),
                                );
                              },
                              body: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  children: [
                                    if ((caseObject.comment ?? '') != '') Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: CommentAlert(
                                          caseObject.comment,
                                          caseObject.check
                                      ),
                                    ),
                                    ThumbnailsRow(
                                      photos: caseObject.photos,
                                      photosPath: caseObject.photosPath,
                                    ),
                                    TextButton.icon(
                                      style: getTextButtonStyle(
                                        TextButtonStyle(size: 1, theme: 'secondary')
                                      ),
                                      onPressed: () => widget.goToStep(step, caseObject),
                                      label: const Text('Добавить фотографии'),
                                      icon: const Icon(Icons.add_a_photo_outlined),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              isExpanded: buildingStepIndex == expandedBuildingStepIndex,
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    isExpanded: buildingIndex == expandedBuildingIndex,
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 0.5),
          ],
        ),

        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            style: getTextButtonStyle(TextButtonStyle(size: 1, theme: 'primary')),
            onPressed: _showAddBuildingSelect,
            label: const Text('Добавить строение'),
            icon: const Icon(Icons.add_home_outlined),
          ),
        ),
        const SizedBox(height: 18),

      ],
    );

  }

  _showAddBuildingSelect() {

    final List<Widget> options = <Map<String, String>>[
      {
        'name': 'Основное строение\n(жилой/садовый дом)',
        'type': 'mainBuilding'
      },
      {
        'name': 'Баня отдельностоящая',
        'type': 'bathhouse'
      },
      {
        'name': 'Гараж отдельностоящий',
        'type': 'garage'
      },
    ].map((option) => SimpleDialogOption(
      onPressed: () => _addBuildingToObjects(
          CheckupHouseCaseObject(
            parent: 'buildings',
            type: option['type']!,
            name: option['name'],
          )
      ),
      padding: EdgeInsets.zero,
      child: Column(
          children: [
            const SizedBox(height: 14),
            Text(option['name']!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center,),
            const SizedBox(height: 16),
            const Divider(height: 0),
          ]
      ),
    ),
    ).toList();

    options.add(
        SimpleDialogOption(
          child: Column(
            children: [
              Form(
                key: addBuildingFormKey,
                child: TextFormField(
                  controller: _addBuildingController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    border: UnderlineInputBorder(),
                    label: Center(
                        child: Text('ввести своё название')
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Введите или выберите из списка' : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                  TextButton(
                    onPressed: () => _addBuildingToObjects(
                        CheckupHouseCaseObject(
                          type: 'otherBuilding',
                          parent: 'buildings',
                          name: _addBuildingController.text,
                        )
                    ),
                    child: const Text('ОК'),
                  ),
                ],
              ),
            ],
          ),
        )
    );

    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Выберите или введите название строения'),
            children: options,
          );
        }
    );

  }

  void _addBuildingToObjects(CheckupHouseCaseObject object) {
    if (object.type == 'otherBuilding' && !addBuildingFormKey.currentState!.validate()) return;
    // если название уже было, добавляем инкремент
    if (buildingsNames.contains(object.name)) {
      object.name = addIncrementToString(object.name ?? '', buildingsNames);
    }
    widget.caseObjects.add(object);
    widget.caseBuildings.add(object);
    // раскроем добавленное строение. но только если это первое,
    // иначе баг: https://github.com/flutter/flutter/issues/128646
    if (widget.caseBuildings.length == 1) {
      _openBuildingPanel(widget.caseBuildings.length - 1);
    }
    else {
      setState(() {
        expandedBuildingIndex = null;
      });
    }
    context.pop();
  }

  // раскрываем панель определённого строения, закрываем другие
  void _openBuildingPanel(int buildingIndexToOpen) {
    final bool isClosing = expandedBuildingIndex == buildingIndexToOpen;
    setState(() {
      expandedBuildingIndex = null;
      // закрываем вкладки шагов строений
      _toggleBuildingStepPanel(null, doSetState: false);
    });
    if (!isClosing) {
      setState(() {
        expandedBuildingIndex = buildingIndexToOpen;
      });
    }
  }

  // раскрываем панель определённого шага строения, закрываем другие
  void _toggleBuildingStepPanel(int? stepIndexToOpen, {bool doSetState = true}) {
    expandedBuildingStepIndex = stepIndexToOpen;
    if (doSetState) setState(() {});
  }

}
