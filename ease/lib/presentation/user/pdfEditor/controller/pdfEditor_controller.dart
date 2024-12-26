import 'dart:convert';

import 'package:ease/core/utils/Routes/routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void onInit() {
    super.onInit();
    PDFRenderer.initializeRenderer();
    loadRecentFiles();
  }

  @override
  void onClose() {
    textEditingController.dispose();
    saveRecentFiles();
    super.onClose();
  }

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
          size: 0
        );

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

      // Check if the file path is valid before proceeding
      if (path.isEmpty) {
        throw FormatException("Invalid file path.");
      }

      document.value = PDFDocument(filePath: path);
      resetZoom();
      bookmarks.clear();
      drawingPoints.clear();
      currentPage.value = 1;

      await PDFRenderer.platform.invokeMethod('openDocument', {
        'path': path,
      });

      update();
      Get.toNamed(AppRoutes.pdfEditView);
    } on FormatException catch (e) {
      // Handle specific format errors (e.g., invalid file path)
      Get.snackbar('Error', 'Invalid file path: $e',
          snackPosition: SnackPosition.BOTTOM);
    } on PlatformException catch (e) {
      // Handle errors specific to platform methods (e.g., invoking platform channels)
      Get.snackbar('Error', 'Platform error: $e',
          snackPosition: SnackPosition.BOTTOM);
    } on Exception catch (e) {
      // Catch any general errors not specifically handled above
      Get.snackbar('Error', 'An unexpected error occurred: $e',
          snackPosition: SnackPosition.BOTTOM);
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
