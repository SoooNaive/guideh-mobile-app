import 'package:flutter/material.dart';
import 'package:guideh/theme/theme.dart';


class GuaranteeLettersFilter extends StatefulWidget {
  final bool showActive;
  final bool showArchive;

  const GuaranteeLettersFilter({
    super.key,
    required this.showActive,
    required this.showArchive,
  });

  @override
  State<GuaranteeLettersFilter> createState() => _GuaranteeLettersFilterState();
}

class _GuaranteeLettersFilterState extends State<GuaranteeLettersFilter> {
  late bool showActive;
  late bool showArchive;

  @override
  void initState() {
    showActive = widget.showActive;
    showArchive = widget.showArchive;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final bool doneButtonIsDisabled = !showActive && !showArchive;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Фильтры'),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CloseButton(),
          ),
        ],
      ),
      titlePadding: EdgeInsets.fromLTRB(24, 15, 10, 5),
      contentPadding: EdgeInsets.all(11),
      actionsPadding: EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            children: [
              Checkbox(
                value: showActive,
                onChanged: (bool? value) => setState(() => showActive = !showActive),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => showActive = !showActive),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('Активные'),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Checkbox(
                value: showArchive,
                onChanged: (bool? value) => setState(() => showArchive = !showArchive),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => showArchive = !showArchive),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('Архивные'),
                ),
              ),
            ],
          ),

        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'showActive': true,
            'showArchive': false,
          }),
          child: const Text('Сбросить'),
        ),

        TextButton(
          onPressed: doneButtonIsDisabled ? null : () => Navigator.of(context).pop({
            'showActive': showActive,
            'showArchive': showArchive,
          }),
          style: TextButton.styleFrom(
            backgroundColor: primaryLightColor,
            disabledBackgroundColor: Colors.white,
            disabledForegroundColor: Colors.black26
          ),
          child: const Text('Применить'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}
