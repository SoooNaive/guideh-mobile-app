String? dateTextValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Укажите дату';
  } else if (value.length != 10 || !dateRegExp.hasMatch(value)) {
    return 'Неверный формат даты';
  }

  final parts = value.split('.');
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);

  // Проверка диапазонов дней и месяцев
  if (month < 1 || month > 12) {
    return 'Неверный месяц';
  }

  if (day < 1 || day > daysInMonth(month, year)) {
    return 'Неверный день';
  }

  return null;
}

int daysInMonth(int month, int year) {
  // Проверка на високосный год
  final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  switch (month) {
    case 2: // Февраль
      return isLeapYear ? 29 : 28;
    case 4: case 6: case 9: case 11: // Апрель, Июнь, Сентябрь, Ноябрь
    return 30;
    default:
      return 31; // Остальные месяцы
  }
}

final RegExp dateRegExp = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
