import 'package:ease/presentation/user/pdfEditor/views/widgets/drawingPainter.dart';
import 'package:ease/presentation/user/pdfEditor/views/widgets/toolBar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/pdfEditor_controller.dart';
import 'pdfEditingOverlay.dart';
import 'pdfRenderView.dart';

// Update PDFEditorView to include new features
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
          Obx(
            () => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : PDFRenderView(
                    document: controller.document.value,
                    currentPage: controller.currentPage.value,
                    scale: controller.scale.value,
                  ),
          ),
          const EditingOverlay(),
          const PDFDrawingOverlay(),
          const ToolbarWidget(),
        ],
      ),
    );
  }
}

