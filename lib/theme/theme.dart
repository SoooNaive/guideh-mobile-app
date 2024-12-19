import 'package:flutter/material.dart';

const double borderRadiusSmall = 8.0;
const double borderRadiusBig = 10.0;

const double minimumButtonHeightSmall = 42;
const double minimumButtonHeightBig = 48;

final ThemeData baseTheme = ThemeData.light();
const Color primaryColor = Color(0xFF33558d);
const Color primaryLightColor = Color(0xFFE0E7FF);
const Color secondaryColor = Colors.blue;
const Color secondaryDarkColor = Color(0xFF2485D3);
const Color secondaryLightColor = Color(0xFFE0F0FF);
const Color successColor = Colors.green;

final appTheme = baseTheme.copyWith(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    secondary: secondaryColor,
    onSecondary: Colors.white,
    error: Color(0xFFD01818),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF666666),
  ),

  scaffoldBackgroundColor: const Color(0xFFF5F5F5),

  bottomAppBarTheme: const BottomAppBarTheme(
    color: primaryColor,
    shadowColor: Colors.black,
  ),

  expansionTileTheme: const ExpansionTileThemeData(
    shape: Border.symmetric(horizontal: BorderSide(color: Colors.black12)),
  ),

  iconTheme: const IconThemeData(
    color: primaryColor,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    unselectedIconTheme: IconThemeData(
      color: secondaryColor,
    ),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: secondaryColor
  ),

  listTileTheme: const ListTileThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFF444444),
    ),
    subtitleTextStyle: TextStyle(
      height: 1.25,
      color: Color(0xFF777777),
    ),
  ),

  cardTheme: CardTheme(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusBig),
    ),
    color: Colors.white,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(minimumButtonHeightSmall, minimumButtonHeightSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
      elevation: 3,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      iconColor: Colors.white,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(minimumButtonHeightSmall, minimumButtonHeightSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      disabledForegroundColor: const Color(0xff728ebe),
      minimumSize: const Size(minimumButtonHeightSmall, minimumButtonHeightSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSmall),
      ),
    ),
  ),

  appBarTheme: const AppBarTheme(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
  ),

  dialogTheme: const DialogTheme(
    backgroundColor: Colors.white,
  ),

  dividerTheme: const DividerThemeData(
    color: Colors.black12,
  ),

  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.white,
  ),

  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Colors.grey
  ),

  tabBarTheme: const TabBarTheme(
    labelStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    unselectedLabelColor: Colors.white,
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w400,
    ),
  ),

);


// TextButton style

// theme: primaryLight
// size: 2 – большой

getTextButtonStyle([TextButtonStyle? style]) {
  final Color textColor;
  final Color backgroundColor;
  final bool isBig = style?.size != 1;
  switch (style?.theme) {
    case 'primaryLight':
      textColor = primaryColor;
      backgroundColor = primaryLightColor;
      break;
    case 'secondaryLight':
      textColor = primaryColor;
      backgroundColor = secondaryLightColor;
      break;
    case 'secondaryAccent':
      textColor = secondaryColor;
      backgroundColor = secondaryLightColor;
      break;
    case 'secondary':
      textColor = Colors.white;
      backgroundColor = secondaryColor;
      break;
    case 'success':
      textColor = Colors.white;
      backgroundColor = successColor;
      break;
    case 'errorLight':
      textColor = const Color(0xFFAA3333);
      backgroundColor = const Color(0xFFF8E6E6);
      break;
    case 'primary':
    default:
      textColor = Colors.white;
      backgroundColor = primaryColor;
  }

  return TextButton.styleFrom(
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        isBig ? borderRadiusBig : borderRadiusSmall
      ),
    ),
    padding: EdgeInsets.symmetric(
      vertical: isBig ? 14 : 13,
      horizontal: 8
    ),
    minimumSize: Size.fromHeight(
      isBig ? minimumButtonHeightBig : minimumButtonHeightSmall,
    ),
    alignment: Alignment.center,
    foregroundColor: textColor,
    textStyle: TextStyle(
      color: textColor,
      fontSize: isBig ? 16 : 14,
      fontWeight: FontWeight.bold,
    ),
    disabledForegroundColor: style?.theme == 'success'
      ? Colors.green.shade200
      : null,
    iconColor: textColor,
  );
}

class TextButtonStyle {
  final int? size;
  final String? theme;
  TextButtonStyle({
    this.size,
    this.theme,
  });
}

