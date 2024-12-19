import 'package:flutter/material.dart';
import 'package:guideh/theme/theme.dart';

import 'functions.dart';
import 'models.dart';

class StepCommon extends StatefulWidget {
  final StepData step;
  final CheckupHouseCaseObject caseObject;
  final Function(StepData previousStep, CheckupHouseCaseObject previousCaseObject) goToStep;
  const StepCommon({
    super.key,
    required this.step,
    required this.caseObject,
    required this.goToStep,
  });

  @override
  State<StepCommon> createState() => _StepCommonState();
}

class _StepCommonState extends State<StepCommon> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if ((widget.caseObject.comment ?? '') != '') Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CommentAlert(
                widget.caseObject.comment,
                widget.caseObject.check
            ),
          ),
          ThumbnailsRow(
            photos: widget.caseObject.photos,
            photosPath: widget.caseObject.photosPath,
          ),
          TextButton.icon(
              style: getTextButtonStyle(TextButtonStyle(size: 1, theme: 'secondary')),
              onPressed: () => widget.goToStep(widget.step, widget.caseObject),
              label: const Text('Добавить фотографии'),
              icon: const Icon(Icons.add_a_photo_outlined)
          ),
        ],
      ),
    );
  }
}
