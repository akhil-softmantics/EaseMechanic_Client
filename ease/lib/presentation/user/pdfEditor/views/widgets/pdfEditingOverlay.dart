// lib/widgets/editing_overlay.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/annonation_widget.dart';
import '../../controller/pdfEditor_controller.dart';

class EditingOverlay extends StatelessWidget {
  const EditingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PDFController>(
      builder: (controller) {
        final document = controller.document.value;
        if (document == null) return const SizedBox.shrink();

        return Stack(
          children: [
            ...document.textEdits.map(
              (edit) => Positioned(
                left: edit.position.dx,
                top: edit.position.dy,
                child: Text(
                  edit.text,
                  style: TextStyle(
                    fontSize: edit.fontSize,
                    color: edit.color,
                  ),
                ),
              ),
            ),
            ...document.annotations.map(
              (annotation) => Positioned(
                left: annotation.position.dx,
                top: annotation.position.dy,
                child: AnnotationWidget(annotation: annotation),
              ),
            ),
          ],
        );
      },
    );
  }
}
