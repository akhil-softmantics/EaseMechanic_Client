// lib/widgets/editing_overlay.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../models/pdfFileModel.dart';
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

// Create a new widget for text selection overlay
class TextSelectionOverlayForPDF extends StatelessWidget {
  const TextSelectionOverlayForPDF({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PDFController>(
      builder: (controller) {
        if (!controller.isTextSelectionMode.value)
          return const SizedBox.shrink();

        return Stack(
          children: [
            if (controller.selectionStart != null &&
                controller.selectionEnd != null)
              Positioned(
                left: min(
                    controller.selectionStart!.dx, controller.selectionEnd!.dx),
                top: min(
                    controller.selectionStart!.dy, controller.selectionEnd!.dy),
                width: (controller.selectionEnd!.dx -
                        controller.selectionStart!.dx)
                    .abs(),
                height: (controller.selectionEnd!.dy -
                        controller.selectionStart!.dy)
                    .abs(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                ),
              ),
            ...controller.selectedTexts.map(
              (selection) => Positioned(
                left: selection.bounds.left,
                top: selection.bounds.top,
                width: selection.bounds.width,
                height: selection.bounds.height,
                child: GestureDetector(
                  onTap: () => _showEditDialog(context, controller, selection),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, PDFController controller,
      PDFTextSelection selection) {
    final textController = TextEditingController(text: selection.text);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter new text',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.replaceSelectedText(selection, textController.text);
              Get.back();
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }
}
