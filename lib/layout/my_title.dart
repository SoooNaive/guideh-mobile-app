import 'package:flutter/material.dart';

class MyTitle extends StatelessWidget {
  final String text;
  final bool? noAlignment;
  final bool? noPadding;
  const MyTitle(this.text, {
    super.key,
    this.noAlignment,
    this.noPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: noPadding == true
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      alignment: noAlignment == null ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        textAlign: noAlignment == null ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF888888),
          letterSpacing: 0.2,
          fontSize: 16,
          wordSpacing: 3,
        ),
      ),
    );
  }
}