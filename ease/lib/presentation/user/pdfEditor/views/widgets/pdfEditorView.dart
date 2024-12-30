// Update your PDFEditorView to include the new overlay and gesture detection
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/pdfEditor_controller.dart';
import 'drawingPainter.dart';
import 'pdfEditingOverlay.dart';
import 'pdfRenderView.dart';
import 'toolBar.dart';

class PDFEditorView extends StatelessWidget {
  PDFEditorView({Key? key}) : super(key: key);

  final PDFController controller = Get.find<PDFController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveDocument,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Extract Page'),
                onTap: controller.extractPage,
              ),
              PopupMenuItem(
                child: const Text('Rotate 90°'),
                onTap: () => controller.rotatePage(90),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanDown: (details) => controller.handleTextSelection(details.localPosition),
            onPanUpdate: (details) => controller.selectionEnd = details.localPosition,
            child: Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : PDFRenderView(
                      document: controller.document.value,
                      currentPage: controller.currentPage.value,
                      scale: controller.scale.value,
                    ),
            ),
          ),
          const EditingOverlay(),
          // const TextSelectionOverlayForPDF(),
          const PDFDrawingOverlay(),
          const ToolbarWidget(),
        ],
      ),
    );
  }
}