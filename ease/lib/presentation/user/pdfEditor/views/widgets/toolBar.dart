// lib/widgets/toolbar_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/pdfEditor_controller.dart';

// Update ToolbarWidget to include new features
// Updated ToolbarWidget
class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PDFController controller = Get.find<PDFController>();

    return Positioned(
  bottom: 16,
  left: 16,
  right: 16,
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: controller.zoomIn,
              tooltip: 'Zoom In',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: controller.zoomOut,
              tooltip: 'Zoom Out',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.previousPage,
              tooltip: 'Previous Page',
            ),
            Obx(() => Text('Page ${controller.currentPage.value}')),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: controller.nextPage,
              tooltip: 'Next Page',
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => controller.startTextEdit(),
              tooltip: 'Add Text',
            ),
            IconButton(
              icon: const Icon(Icons.highlight),
              onPressed: controller.toggleHighlightMode,
              tooltip: 'Highlight',
            ),
            Obx(() => IconButton(
                  icon: Icon(
                    Icons.text_format,
                    color: controller.isTextSelectionMode.value ? Colors.blue : null,
                  ),
                  onPressed: controller.toggleTextSelectionMode,
                  tooltip: 'Select Text',
                )),
            Obx(() => IconButton(
                  icon: Icon(
                    Icons.draw,
                    color: controller.isDrawingMode.value ? Colors.blue : null,
                  ),
                  onPressed: controller.toggleDrawingMode,
                  tooltip: 'Drawing Mode',
                )),
          ],
        ),
      ),
    ),
  ),
);

  }
}
