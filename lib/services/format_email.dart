import 'package:flutter/services.dart';

class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final String newText = newValue.text;

    // Разрешенные символы: буквы, цифры, точки, подчеркивания, тире и @.
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._@-]*$');

    // Проверяем, соответствует ли текст разрешенным символам.
    if (!emailRegex.hasMatch(newText)) {
      return oldValue;
    }

    // Ограничиваем количество символов '@' до одного.
    final int atCount = '@'.allMatches(newText).length;
    if (atCount > 1) {
      return oldValue;
    }

    // Возвращаем отформатированное значение.
    return newValue;
  }
}