import 'package:flutter/material.dart';
import 'package:guideh/theme/theme.dart';

class CheckupKaskoAlert extends StatelessWidget {
  final Function() closeAlert;
  final IconData? iconData;
  final String text;
  final String textCloseAlert;
  final List<TextButton>? extraButtons;
  const CheckupKaskoAlert({
    super.key,
    required this.closeAlert,
    required this.iconData,
    required this.text,
    required this.textCloseAlert,
    this.extraButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconData != null) Icon(
            iconData,
            color: const Color(0xffffb700),
            size: 120,
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            decoration: BoxDecoration(
              // color: const Color(0xffefeacc),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(
                color: const Color(0xffffb700),
                width: 4,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xffeeaa00),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          TextButton(
            style: getTextButtonStyle(),
            onPressed: closeAlert,
            child: Text(textCloseAlert),
          ),
          if (extraButtons != null && extraButtons!.isNotEmpty)
            ...extraButtons!.map((btn) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: btn,
            )
          ),
        ],
      ),
    );
  }
}
