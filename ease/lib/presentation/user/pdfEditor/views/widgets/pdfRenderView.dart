import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';

import '../../../../../models/pdfFileModel.dart';
import '../../controller/pdfEditor_controller.dart';

class PDFRenderView extends StatelessWidget {
  final PDFDocument? document;
  final int currentPage;
  final double scale;

  const PDFRenderView({
    Key? key,
    required this.document,
    required this.currentPage,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PDFController controller = Get.find<PDFController>();

    if (document == null) {
      return const Center(child: Text('No document loaded'));
    }

    return PDFView(
      filePath: document!.filePath,
      defaultPage: currentPage - 1,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        controller.totalPages.value = pages ?? 0;
      },
      onViewCreated: (PDFViewController pdfViewController) {
        controller.pdfViewController = pdfViewController;
      },
      onPageChanged: (int? page, int? total) {
        if (page != null) {
          controller.currentPage.value = page + 1;
        }
      },
      onError: (error) {
        Get.snackbar(
          'Error',
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
}
