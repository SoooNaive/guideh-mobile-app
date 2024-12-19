import 'dart:convert';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guideh/pages/checkup_house/step_buildings.dart';
import 'package:guideh/services/functions.dart';
import 'package:guideh/services/http.dart';
import 'package:guideh/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'functions.dart';
import 'models.dart';
import 'step_common.dart';


class CheckupHouse extends StatefulWidget {
  final String? parentId;
  final String? parentType;
  final List<CheckupHouseCaseObject> httpCaseObjects;
  const CheckupHouse({
    super.key,
    required this.parentId,
    this.parentType,
    required this.httpCaseObjects,
  });

  @override
  State<CheckupHouse> createState() => _CheckupHouseState();
}

class _CheckupHouseState extends State<CheckupHouse> with TickerProviderStateMixin {

  bool isSaving = false;
  int saveProgress = 0;
  int saveTotalObjectsParts = 1;
  late int? expandedMainStepIndex;

  late List<CheckupHouseCaseObject> caseObjects = [];
  late List<CheckupHouseCaseObject> buildings = [];

  // юзаем при отправке
  List<int> objectsPartsSentIndexes = [];
  List<dynamic> objectsWithNewPhotos = [];
  List<CheckupHouseCaseObject> objectsWithoutNewPhotos = [];

  @override
  void initState() {
    super.initState();
    caseObjects = widget.httpCaseObjects;
    buildings = caseObjects.where(
      (object) => object.parent == 'buildings'
    ).toList();
    // если набор объектов по умолчанию → раскроем первый шаг
    expandedMainStepIndex = caseObjects == defaultCaseObjects ? 0 : null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      floatingActionButton: !isSaving ? FloatingActionButton(
        onPressed: () {

          // проверка валидности

          bool foundInvalidPhotos = false;
          bool foundNotEnoughtPhotos = false;

          for (var caseObject in caseObjects) {
            final StepData? step = getStepByType(caseObject.type);
            if (step == null || step.child == null) continue;
            // todo: найдены неодобренные фотки
            updateStepStatus(step, caseObject);
            updateBuildingStepObjectValidity(step, caseObject, caseObjects);
            if (caseObject.invalid == true) {
              foundInvalidPhotos = true;
            }
            if (caseObject.photosCount < (step.minPhotos ?? 0)) {
              foundNotEnoughtPhotos = true;
            }
          }
          // todo: надо ли перед этим обновить стейт для валидации билдингов?
          updateBuildingsStepStatus(buildings);
          if (foundInvalidPhotos || foundNotEnoughtPhotos) {
            setState(() { });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Необходимо добавить недостающие фото.')),
            );
            return;
          }

          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Завершить осмотр'),
                content: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вы уверены, что хотите полностью завершить осмотр?'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Отмена'),
                    onPressed: () => dialogContext.pop(),
                  ),
                  TextButton(
                    child: const Text('Завершить осмотр'),
                    onPressed: () {
                      setState(() {
                        isSaving = true;
                        // при первой отправке:
                        // успешно отправлено – ноль
                        objectsPartsSentIndexes = [];
                        // объекты без новых фоток
                        objectsWithoutNewPhotos = caseObjects.where(
                          (object) => object.photosPath == null || object.photosPath!.isEmpty
                        ).toList();
                        // объекты с новыми фотками
                        objectsWithNewPhotos = caseObjects.where(
                          (object) => object.photosPath != null && object.photosPath!.isNotEmpty
                        )
                        // конвертим в json, чтобы старые фотки удалились (photos)
                        // а новые (photosPath) переконвертились для бэка (метод toJson)
                        .map((obj) => jsonDecode(jsonEncode(obj))).toList();
                      });
                      dialogContext.pop();
                      _sendPhotos();
                    },
                  ),
                ],
              );
            },
          );

        },
        child: const Icon(Icons.done),
      )
      : null,

      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => exitCheckupDialog(context),
          icon: Image.asset('assets/images/mini-logo-white.png', height: 30),
        ),
        title: const Text('Осмотр загородного дома'),
      ),

      body: isSaving ?

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 25),
              const Text(
                "Отправка фотографий.\nПожалуйста, подождите.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: LinearProgressIndicator(
                  value: saveProgress / saveTotalObjectsParts,
                  color: secondaryColor,
                  backgroundColor: const Color(0xffdfdfdf),
                  minHeight: 6,
                ),
              ),
            ],
          )
        )

        : showData(),

    );
  }


  Widget showData() {

    if ((widget.parentId ?? '') == '') {
      return const Center(
        child: Text('Ошибка: не передан ID родительского документа. Убедитесь в корректности ссылки на осмотр или обратитесь в техподдержку.')
      );
    }

    if (caseObjects.isEmpty) {
      return const Center(
        child: Text('Ошибка: не определены объекты кейса. Убедитесь в корректности ссылки на осмотр или обратитесь в техподдержку.')
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xffe5e5e5)),
            child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                _toggleMainStepPanel(index);
              },
              expandedHeaderPadding: EdgeInsets.zero,
              elevation: 4,
              children: stepsMain.mapIndexed((int stepIndex, StepData step) {

                final CheckupHouseCaseObject? caseObject = caseObjects.firstWhereOrNull(
                  (object) => object.type == step.type,
                );

                if (caseObject == null) {
                  return ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('В кейсе не найден объект с типом ${step.type}'),
                          ],
                        ),
                      );
                    },
                    body: const SizedBox.shrink(),
                  );
                }

                final int photosCount = caseObject.photosCount;
                // если шаг строений – проверим его check
                if (step.type == 'buildings') {
                  for (var building in buildings) {
                    if (building.check == false) {
                      step.status = StepStatus.invalid;
                      break;
                    }
                  }
                }
                final bool invalidOrCheckFalse = step.status == StepStatus.invalid || caseObject.check == false;

                // панель главного шага
                return ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      minVerticalPadding: 12,
                      horizontalTitleGap: 2,

                      // номер основного шага
                      leading: Container(
                        alignment: Alignment.center,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isExpanded
                            ? invalidOrCheckFalse
                              ? Colors.red
                              : const Color(0xff525252)
                            : invalidOrCheckFalse
                              ? const Color(0x24ff0000)
                              : const Color(0xffe5e5e5),
                        ),
                        child: Text(
                          (stepIndex + 1).toString(),
                          style: TextStyle(
                            color: isExpanded
                              ? Colors.white
                              : invalidOrCheckFalse
                                ? Colors.red
                                : Colors.black,
                            fontWeight: isExpanded ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),

                      // название основного шага
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                                fontWeight: isExpanded ? FontWeight.w500 : FontWeight.normal
                            ),
                          ),
                          if (step.type != 'buildings') const SizedBox(height: 8),
                          if (step.type != 'buildings') Wrap(
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
                                    color: step.status == StepStatus.invalid ? Colors.red : Colors.grey,
                                  )
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },

                  body: step.type != 'buildings'

                  // шаг
                  ? StepCommon(
                    step: step,
                    caseObject: caseObject,
                    goToStep: _goToStep,
                  )

                  // шаг "строения" → аккордеон объектов строений
                  : StepBuildings(
                    caseObjects: caseObjects,
                    caseBuildings: buildings,
                    goToStep: _goToStep,
                  ),

                  isExpanded: stepIndex == expandedMainStepIndex,
                );

              }).toList(),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );

  }


  Future<dynamic> _sendPhotos() async {

    SharedPreferences preferences = await SharedPreferences.getInstance();

    // отправляем разом все объекты без новых фоток
    // и отдельно каждый объект с новыми фотками
    final List<List<dynamic>> objectsParts = [
      objectsWithoutNewPhotos,
      ...objectsWithNewPhotos.map((object) => [object])
    ];

    print('_sendPhotos! объектов: ${objectsParts.length}');

    String? errorMessage;
    int objectsPartIndex = -1;

    for(var objectsPart in objectsParts) {
      objectsPartIndex++;

      print('индекс $objectsPartIndex...');

      if (objectsPartsSentIndexes.contains(objectsPartIndex)) {
        print('индекс $objectsPartIndex – уже был отправлен');
        continue;
      }

      final saveResponse = await Http.mobApp(
        ApiParams('Checkuphouse', 'Save', {
          // 'token': await Auth.token,
          'ParentId': widget.parentId,
          'ParentType': widget.parentType ?? '',
          'Author': preferences.getString('userName') ?? '',
          'Phone': preferences.getString('phone') ?? '',
          'Data': objectsPart,
        })
      );

      if (saveResponse == null) {
        errorMessage = 'Ошибка #701';
      }
      else if (!saveResponse.containsKey('Error')) {
        errorMessage = 'Ошибка #702';
      }
      else if (saveResponse['Error'] == 3 && saveResponse.containsKey('Message')) {
        errorMessage = saveResponse['Message'];
      }
      else if (saveResponse['Error'] is String && saveResponse['Error'] != '') {
        errorMessage = saveResponse['Error'];
      }
      else if (saveResponse['Error'] is List && saveResponse['Error'].isNotEmpty) {
        errorMessage = saveResponse['Error'][0];
      }
      else if (!saveResponse.containsKey('ParentId')) {
        errorMessage = 'Ошибка #703';
      }
      else {
        setState(() {
          if (saveProgress == 0) saveTotalObjectsParts = objectsParts.length;
          if (!objectsPartsSentIndexes.contains(objectsPartIndex)) {
            objectsPartsSentIndexes.add(objectsPartIndex);
          }
          saveProgress++;
        });
        print('индекс $objectsPartIndex – УСПЕХ (${objectsPartsSentIndexes.length} / ${objectsParts.length})');
      }

      if (errorMessage != null) {
        print(errorMessage);
        break;
      }

    }

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(errorMessage),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _sendPhotos();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white12,
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
          duration: const Duration(days: 1),
        )
      );
      return;
    }

    else if (saveProgress == saveTotalObjectsParts && mounted) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Успешно!'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(saveResponse.toString()),
                  Text('Все фотографии загружены. Ожидайте, вам поступит СМС с результатами проверки.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.go('/polis_list'),
                style: getTextButtonStyle(TextButtonStyle(
                    size: 1, theme: 'primary')
                ),
                child: const Text('Перейти в приложение'),
              ),
            ],
            actionsOverflowAlignment: OverflowBarAlignment.center,
            actionsOverflowButtonSpacing: 5,
            actionsPadding: const EdgeInsets.all(15),
          );
        },
      );
    }
  }


  void _toggleMainStepPanel(int stepIndexToOpen) {
    setState(() {
      expandedMainStepIndex = expandedMainStepIndex != stepIndexToOpen
          ? stepIndexToOpen
          : null;
    });
  }


  Future<void> _goToStep(StepData step, CheckupHouseCaseObject? caseObject) async {
    print('go to step!');
    if (step.child == null) return;

    // todo: развернуть нужный этап

    bool? goNextStep = await Navigator.push(context, MaterialPageRoute(
        builder: (context) => step.child!(step, caseObject)
    ));
    // тут открытый шаг строения – закрылся
    if (caseObject != null) {
      setState(() {
        if (allSteps.indexOf(step) >= stepsMain.length) {
          updateBuildingStepObjectValidity(step, caseObject, caseObjects);
        }
        updateStepStatus(step, caseObject);
      });
    }
    // if popped true → go to next step
    if ((goNextStep ?? false) != false) {
      _goNextStep(step, caseObject);
    }
  }

  void _goNextStep(StepData previousStep, [CheckupHouseCaseObject? previousCaseObject]) async {
    print('go next step!');
    final int stepIndexFromAll = allSteps.indexOf(previousStep);
    CheckupHouseCaseObject? nextCaseObject;

    // следующий шаг есть
    if (stepIndexFromAll + 1 < allSteps.length) {
      final nextStep = allSteps[stepIndexFromAll + 1];
      // next step is 3.buildings ? open it's expansion panel
      if (nextStep.type == 'buildings') {
        _toggleMainStepPanel(stepIndexFromAll + 1);
        return;
      }
      final nextStepIsBuildingStep = stepIndexFromAll >= stepsMain.length;
      // main step - ищем первый caseObject по type
      if (!nextStepIsBuildingStep) {
        nextCaseObject = caseObjects.firstWhere(
          (object) => object.type == nextStep.type
        );
      }
      // building step - ищем первый caseObject по type и parent (привязка к строению)
      else {
        if (previousCaseObject == null) return;
        nextCaseObject = caseObjects.firstWhere(
          (object) => object.type == nextStep.type && object.parent == previousCaseObject.parent,
          // если нет такого caseObject → добавим его в caseObjects
          orElse: () {
            final newCaseObject = CheckupHouseCaseObject(
              type: nextStep.type,
              parent: previousCaseObject.parent,
              photos: [],
              photosPath: [],
            );
            caseObjects.add(newCaseObject);
            return newCaseObject;
          }
        );
      }

      // раскрываем панель следующего шага
      if (expandedMainStepIndex != null && expandedMainStepIndex! < (stepsMain.length - 1)) {
        expandedMainStepIndex = expandedMainStepIndex! + 1;
      }

      _goToStep(nextStep, nextCaseObject);
      return;
    }

    // шаги закончились
    // свернём открытый шаг строений
    print('шаги закончились!');
    expandedMainStepIndex = null;
    setState(() {});

  }

}

