// lib/bindings/pdf_editor_bindings.dart
import 'package:get/get.dart';

import '../controller/pdfEditor_controller.dart';

class PdfEditorBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PDFController>(() => PDFController());
  }
}
