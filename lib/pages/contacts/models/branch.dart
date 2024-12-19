import 'package:flutter/material.dart';

class Branch {
  Branch({
    required this.index,
    required this.id,
    required this.cityId,
    required this.cityName,
    required this.name,
    required this.address,
    required this.phone,
    required this.timeWorkdays,
    required this.timeBreak,
    required this.timeSaturday,
    required this.timeSunday,
    required this.email,
    required this.type,
    required this.note,
    required this.xCoordinates,
    required this.yCoordinates,
  });

  int index;
  String id;
  String cityId;
  String cityName;
  String name;
  String address;
  String phone;
  String timeWorkdays;
  String timeBreak;
  String timeSaturday;
  String timeSunday;
  String email;
  String type;
  String note;
  String xCoordinates;
  String yCoordinates;

}

// часы работы - формируем строку
String getWorkHoursString(Branch branch) {
  final now = DateTime.now();
  List<String> hoursArray = ['', ''];

  // будни
  if (now.weekday <= 5) {
    hoursArray = branch.timeWorkdays.split('-');
  }
  // суббота
  else if (now.weekday == 6) {
    if (branch.timeSaturday != '') {
      hoursArray = branch.timeSaturday.split('-');
    }
    else {
      return 'Сегодня выходной';
    }
  }
  // воскресенье
  else if (now.weekday == 7) {
    if (branch.timeSunday != '') {
      hoursArray = branch.timeSunday.split('-');
    }
    else {
      return 'Сегодня выходной';
    }
  }

  final hoursStart = hoursArray[0];
  final hoursEnd = hoursArray[1];

  return 'Сегодня $hoursStart–$hoursEnd';
}

// формируем лист виджетов для отображения графика работы по дням
List<Widget> getWorkingHoursDays(Branch branch, double? padding) {

  Widget? breakTimeTextWidget = (branch.timeBreak != '')
    ? Text('Перерыв: ${branch.timeBreak.replaceAll('-', '–')}')
    : null;

  var workingDaysWidgetList = <Widget>[];
  workingDaysWidgetList.add(const Divider(height: 0));
  workingDaysWidgetList.add(
    ListTile(
      leading: const Text('Пн-Пт'),
      title: Text(branch.timeWorkdays.replaceAll('-', '–')),
      subtitle: breakTimeTextWidget,
      dense: true,
    )
  );
  workingDaysWidgetList.add(const Divider(height: 0));
  workingDaysWidgetList.add(
    ListTile(
      leading: (branch.timeSaturday == branch.timeSunday) ? const Text('Сб-Вс') : const Text('Сб'),
      textColor: branch.timeSaturday == '' ? Colors.red : Colors.black,
      title: Text(branch.timeSaturday != '' ? branch.timeSaturday.replaceAll('-', '–') : 'Выходной'),
      subtitle: (branch.timeSaturday == '' && branch.timeSunday == '') ? null : breakTimeTextWidget,
      dense: true
    )
  );
  if (branch.timeSaturday != branch.timeSunday) {
    workingDaysWidgetList.add(const Divider(height: 0));
    workingDaysWidgetList.add(
      ListTile(
        leading: const Text('Вс'),
        textColor: branch.timeSunday == '' ? Colors.red : Colors.black,
        title: Text(branch.timeSunday != '' ? branch.timeSunday.replaceAll('-', '–') : 'Выходной'),
        subtitle: (branch.timeSunday != '') ? breakTimeTextWidget : null,
        dense: true
      )
    );
  }

  return workingDaysWidgetList;
}