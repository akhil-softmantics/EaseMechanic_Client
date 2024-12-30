import 'dart:convert';
import 'dart:io';

import 'package:ease/core/utils/Routes/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../core/utils/pdfRender.dart';
import '../../../../models/pdfFileModel.dart';

class PDFController extends GetxController {
  final Rx<PDFDocument?> document = Rx<PDFDocument?>(null);
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxDouble scale = 1.0.obs;
  final RxList<PDFFile> recentFiles = <PDFFile>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isDrawingMode = false.obs;
  final RxList<Offset> drawingPoints = <Offset>[].obs;
  final RxBool isTextMode = false.obs;
  final RxBool isHighlightMode = false.obs;
  final RxList<PDFBookmark> bookmarks = <PDFBookmark>[].obs;

  late PDFViewController pdfViewController;
  final textEditingController = TextEditingController();
  Color currentColor = Colors.black;
  double currentFontSize = 14.0;

  final RxList<PDFTextSelection> selectedTexts = <PDFTextSelection>[].obs;
  final RxBool isTextSelectionMode = false.obs;
  final RxBool isEditingText = false.obs;
  Offset? selectionStart;
  Offset? selectionEnd;
  PdfTextExtractor? _textExtractor;
  final RxList<PDFTextEdit> activeTextEdits = <PDFTextEdit>[].obs;

  // late PDFViewController pdfViewController;
  PdfDocument? pdfDocument;
  // final RxBool isEditingText = false.obs;
  // PdfDocument? pdfDocument;
  @override
  void onInit() {
    super.onInit();
    PDFRenderer.initializeRenderer();
    loadRecentFiles();
  }

  @override
  void onClose() {
    PDFRenderer.closeRenderer();
    textEditingController.dispose();
    saveRecentFiles();
    pdfViewController.reactive;
    super.onClose();
  }

// Add this method to your PDFController class
  void startInlineEdit(PDFTextEdit textEdit) {
    activeTextEdits.add(textEdit);
    update();
  }

  // Add to your PDFController class
  Future<void> updateText(int pageNumber, Rect bounds, String newText) async {
    try {
      if (pdfDocument == null) return;

      final page = pdfDocument!.pages[pageNumber - 1];
      final pageSize = page.size;
      final scale = Get.size.width / pageSize.width;

      final pdfBounds = Rect.fromLTWH(
        bounds.left / scale,
        bounds.top / scale,
        bounds.width / scale,
        bounds.height / scale,
      );

      // Create a standard font
      final font = PdfStandardFont(PdfFontFamily.helvetica, currentFontSize);

      // Draw the new text
      page.graphics.drawString(
        newText,
        font,
        bounds: pdfBounds,
        brush: PdfSolidBrush(PdfColor(
          currentColor.red,
          currentColor.green,
          currentColor.blue,
        )),
      );

      await saveChanges();
      await pdfViewController.setPage(pageNumber - 1);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update text: $e');
    }
  }
  // Future<void> deleteSelectedText(PDFTextSelection selection) async {
  //   try {
  //     await PDFRenderer.platform.invokeMethod('replaceText', {
  //       'page': selection.pageNumber - 1,
  //       'rect': {
  //         'left': selection.bounds.left,
  //         'top': selection.bounds.top,
  //         'right': selection.bounds.right,
  //         'bottom': selection.bounds.bottom,
  //       },
  //       'newText': '',
  //     });

  //     selectedTexts.remove(selection);
  //     update();
  //     await pdfViewController.setPage(currentPage.value - 1);
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to delete text: $e',
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }

// In PDFController class, replace the replaceSelectedText method with:

  Future<void> replaceSelectedText(
      PDFTextSelection selection, String newText) async {
    try {
      if (pdfDocument == null) return;

      PdfPage page = pdfDocument!.pages[selection.pageNumber - 1];
      final pageSize = page.size;
      final scale = Get.size.width / pageSize.width;

      // Convert screen coordinates to PDF coordinates
      final pdfBounds = Rect.fromLTWH(
        selection.bounds.left / scale,
        selection.bounds.top / scale,
        selection.bounds.width / scale,
        selection.bounds.height / scale,
      );

      // Create a text element with the new text
      PdfStandardFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      PdfTextElement textElement = PdfTextElement(
        text: newText,
        font: font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );

      // Draw the new text
      textElement.draw(
        page: page,
        bounds: pdfBounds,
      );

      // Save changes and refresh the view
      await saveChanges();
      selectedTexts.remove(selection);
      update();

      // Refresh the current page
      await pdfViewController.setPage(currentPage.value - 1);
    } catch (e) {
      Get.snackbar('Error', 'Failed to replace text: $e');
    }
  }

  Future<void> deleteSelectedText(PDFTextSelection selection) async {
    try {
      await replaceSelectedText(
          selection, ''); // Replace with empty string to delete
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete text: $e');
    }
  }

  Future<void> saveChanges() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Save the modified PDF
      File(outputPath).writeAsBytes(await pdfDocument!.save());

      // Update the document path
      document.value = PDFDocument(filePath: outputPath);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save changes: $e');
    }
  }

  Future<void> finalizeTextSelection() async {
    if (selectionStart != null && selectionEnd != null) {
      await _processTextSelection();
      selectionStart = null;
      selectionEnd = null;
      update();
    }
  }

  // Add this method to toggle text selection mode
  void toggleTextSelectionMode() {
    isTextSelectionMode.value = !isTextSelectionMode.value;
    isDrawingMode.value = false;
    isHighlightMode.value = false;
    isTextMode.value = false;
    update();
  }

  // Handle text selection
  void handleTextSelection(Offset position) {
    if (!isTextSelectionMode.value) return;

    if (selectionStart == null) {
      selectionStart = position;
    } else {
      selectionEnd = position;
      _processTextSelection();
    }
    update();
  }

  Future<void> _handleTapForEditing(BuildContext context, Offset point) async {
    try {
      if (pdfDocument == null) return;

      final page = pdfDocument!.pages[currentPage.value - 1];
      final textExtractor = PdfTextExtractor(pdfDocument!);

      // Calculate tap area bounds
      final tapAreaSize = 50.0;
      final bounds = Rect.fromCenter(
        center: point,
        width: tapAreaSize,
        height: tapAreaSize,
      );

      // Extract text around the tap point
      final extractedText = textExtractor.extractText(
        startPageIndex: currentPage.value - 1,
        endPageIndex: currentPage.value - 1,
        // bounds: bounds,
      );

      if (extractedText.isNotEmpty) {
        startInlineEdit(
          PDFTextEdit(
            text: extractedText,
            position: point,
            bounds: bounds,
            pageNumber: currentPage.value,
            fontSize: currentFontSize,
            color: currentColor,
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to extract text: $e');
    }
  }

  // Process the text selection
  Future<void> _processTextSelection() async {
    try {
      if (pdfDocument == null || selectionStart == null || selectionEnd == null)
        return;

      // Create text extractor if not exists
      _textExtractor ??= PdfTextExtractor(pdfDocument!);

      // Convert screen coordinates to PDF coordinates
      // You might need to adjust these calculations based on your PDF view scaling
      final pageSize = pdfDocument!.pages[currentPage.value - 1].size;
      final scale = Get.size.width / pageSize.width;

      final pdfRect = Rect.fromPoints(
        Offset(
          selectionStart!.dx / scale,
          selectionStart!.dy / scale,
        ),
        Offset(
          selectionEnd!.dx / scale,
          selectionEnd!.dy / scale,
        ),
      );

      // Extract text from the selected area
      final extractedText = _textExtractor!.extractText(
        startPageIndex: currentPage.value - 1,
        endPageIndex: currentPage.value - 1,
        // bounds: pdfRect,
      );

      if (extractedText.isNotEmpty) {
        selectedTexts.add(PDFTextSelection(
          bounds: Rect.fromPoints(selectionStart!, selectionEnd!),
          text: extractedText,
          pageNumber: currentPage.value,
        ));
      }

      selectionStart = null;
      selectionEnd = null;
      update();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process text selection: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // // Replace selected text
  // Future<void> replaceSelectedText(String newText) async {
  //   try {
  //     if (selectedTexts.isEmpty) return;

  //     final selection = selectedTexts.last;

  //     await PDFRenderer.platform.invokeMethod('replaceText', {
  //       'page': selection.pageNumber - 1,
  //       'rect': {
  //         'left': selection.bounds.left,
  //         'top': selection.bounds.top,
  //         'right': selection.bounds.right,
  //         'bottom': selection.bounds.bottom,
  //       },
  //       'newText': newText,
  //     });

  //     selectedTexts.removeLast();
  //     update();

  //     // Refresh the page to show changes
  //     await pdfViewController.setPage(currentPage.value - 1);
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to replace text: $e',
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }

  void startHighlight() {
    isHighlightMode.value = true;
    isDrawingMode.value = false;
    isTextMode.value = false;
    update();
  }

  Future<void> rotatePage(int degrees) async {
    try {
      await pdfViewController.setPage(currentPage.value - 1);
      // Since rotateView isn't available, we'll need to implement rotation differently
      // This could be done through a custom platform channel or using a different approach
      // For now, we'll show a message that rotation isn't supported
      Get.snackbar('Note', 'Page rotation is not supported in this version',
          snackPosition: SnackPosition.BOTTOM);
      update();
    } catch (e) {
      Get.snackbar('Error', 'Failed to rotate page: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson = prefs.getStringList('recentFiles') ?? [];
      recentFiles.value = recentFilesJson
          .map((json) => PDFFile.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading recent files: $e');
    }
  }

  Future<void> saveRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFilesJson =
          recentFiles.map((file) => jsonEncode(file.toJson())).toList();
      await prefs.setStringList('recentFiles', recentFilesJson);
    } catch (e) {
      debugPrint('Error saving recent files: $e');
    }
  }

  void zoomIn() {
    scale.value *= 1.25;
    update();
  }

  void zoomOut() {
    scale.value *= 0.75;
    update();
  }

  void resetZoom() {
    scale.value = 1.0;
    update();
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      pdfViewController.setPage(currentPage.value - 1);
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      pdfViewController.setPage(currentPage.value - 1);
    }
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      pdfViewController.setPage(page - 1);
    }
  }

  void toggleDrawingMode() {
    isDrawingMode.value = !isDrawingMode.value;
    isTextMode.value = false;
    isHighlightMode.value = false;
    if (!isDrawingMode.value) {
      saveDrawing();
    }
    update();
  }

  void toggleTextMode() {
    isTextMode.value = !isTextMode.value;
    isDrawingMode.value = false;
    isHighlightMode.value = false;
    update();
  }

  void toggleHighlightMode() {
    isHighlightMode.value = !isHighlightMode.value;
    isDrawingMode.value = false;
    isTextMode.value = false;
    update();
  }

  void addDrawingPoint(Offset point) {
    if (isDrawingMode.value) {
      drawingPoints.add(point);
      update();
    }
  }

  void saveDrawing() {
    if (drawingPoints.isNotEmpty) {
      addAnnotation(
        PDFAnnotation(
          type: AnnotationType.drawing,
          position: drawingPoints.first,
          color: currentColor,
          points: List.from(drawingPoints),
        ),
      );
      drawingPoints.clear();
      update();
    }
  }

  void addBookmark() {
    bookmarks.add(PDFBookmark(
      page: currentPage.value,
      title: 'Bookmark at page ${currentPage.value}',
      timestamp: DateTime.now(),
    ));
    update();
  }

  void removeBookmark(PDFBookmark bookmark) {
    bookmarks.remove(bookmark);
    update();
  }

  void setColor(Color color) {
    currentColor = color;
    update();
  }

  void setFontSize(double size) {
    currentFontSize = size;
    update();
  }

  // Future<void> rotatePage(int degrees) async {
  //   try {
  //     await pdfViewController.setPage(currentPage.value - 1);
  //     await Future.delayed(const Duration(milliseconds: 100));
  //     await pdfViewController.rotateView(degrees);
  //     update();
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to rotate page: $e',
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }

  Future<void> extractPage() async {
    try {
      isLoading.value = true;
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/extracted_page_${currentPage.value}.pdf';

      // Implementation for page extraction
      await PDFRenderer.platform.invokeMethod('extractPage', {
        'sourcePath': document.value!.filePath,
        'outputPath': outputPath,
        'pageNumber': currentPage.value,
      });

      Get.snackbar('Success', 'Page extracted successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to extract page: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPDFFile() async {
    try {
      isLoading.value = true;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final path = result.files.single.path!;
        await openPDF(path);

        final newFile = PDFFile(
            name: result.files.single.name,
            path: path,
            timestamp: DateTime.now(),
            size: 0);

        recentFiles.insert(0, newFile);
        if (recentFiles.length > 10) {
          recentFiles.removeLast();
        }

        await saveRecentFiles();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick PDF file: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openPDF(String path) async {
    try {
      isLoading.value = true;
      // Load PDF with Syncfusion for editing
      pdfDocument = PdfDocument(inputBytes: await File(path).readAsBytes());

      // Set up flutter_pdfview for rendering
      document.value = PDFDocument(filePath: path);
      resetZoom();
      currentPage.value = 1;

      update();
      Get.toNamed(AppRoutes.pdfEditView);
    } catch (e) {
      Get.snackbar('Error', 'Failed to open PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void startTextEdit() {
    Get.dialog(
      AlertDialog(
        title: const Text('Add Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textEditingController,
              decoration: const InputDecoration(
                hintText: 'Enter text',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: () => showColorPicker(),
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: () => showFontSizePicker(),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textEditingController.text.isNotEmpty) {
                addTextEdit(
                  PDFTextEdit(
                    text: textEditingController.text,
                    position: const Offset(100, 100),
                    fontSize: currentFontSize,
                    color: currentColor,
                  ),
                );
                textEditingController.clear();
              }
              Get.back();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showColorPicker() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Color'),
        content: ColorPicker(
          pickerColor: currentColor,
          onColorChanged: setColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void showFontSizePicker() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Font Size'),
        content: Slider(
          value: currentFontSize,
          min: 8,
          max: 72,
          divisions: 32,
          label: currentFontSize.round().toString(),
          onChanged: (value) {
            setFontSize(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void addTextEdit(PDFTextEdit edit) {
    if (document.value != null) {
      document.value!.textEdits.add(edit);
      update();
    }
  }

  void addAnnotation(PDFAnnotation annotation) {
    if (document.value != null) {
      document.value!.annotations.add(annotation);
      update();
    }
  }

  Future<void> saveDocument() async {
    try {
      isLoading.value = true;
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await PDFRenderer.platform.invokeMethod('saveDocument', {
        'sourcePath': document.value!.filePath,
        'outputPath': outputPath,
        'annotations':
            document.value!.annotations.map((a) => a.toJson()).toList(),
        'textEdits': document.value!.textEdits.map((t) => t.toJson()).toList(),
      });

      Get.snackbar('Success', 'Document saved successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save PDF: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> mergePDFs() async {
    try {
      isLoading.value = true;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.length > 1) {
        final paths = result.files.map((f) => f.path!).toList();
        final tempDir = await getTemporaryDirectory();
        final outputPath =
            '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

        await PDFRenderer.platform.invokeMethod('mergePDFs', {
          'paths': paths,
          'outputPath': outputPath,
        });

        await openPDF(outputPath);
        Get.snackbar('Success', 'PDFs merged successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to merge PDFs: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
