import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../models/pdfFileModel.dart';
import '../../controller/pdfEditor_controller.dart';

// Updated PDFTextEditor widget
class PDFTextEditor extends StatelessWidget {
  final PDFController controller;

  const PDFTextEditor({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (!controller.isTextSelectionMode.value) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTapDown: (details) => controller.handleTextSelection(details.localPosition),
            onPanUpdate: (details) {
              if (controller.selectionStart != null) {
                controller.selectionEnd = details.localPosition;
                controller.update();
              }
            },
            onPanEnd: (_) => controller.finalizeTextSelection(),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        }),
        Obx(() => Stack(
          children: controller.selectedTexts.map((selection) {
            return Positioned(
              left: selection.bounds.left,
              top: selection.bounds.top,
              width: selection.bounds.width,
              height: selection.bounds.height,
              child: InkWell(
                onTap: () => _showEditDialog(context, selection),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Center(
                    child: Text(
                      selection.text,
                      style: const TextStyle(backgroundColor: Colors.transparent),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  void _showEditDialog(BuildContext context, PDFTextSelection selection) {
    final textController = TextEditingController(text: selection.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter new text',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () {
                    controller.deleteSelectedText(selection);
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: () {
                    controller.replaceSelectedText(selection, textController.text);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}