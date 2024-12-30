import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../../../models/pdfFileModel.dart';
import '../../controller/pdfEditor_controller.dart';

class PDFTextEditor extends StatelessWidget {
  final PDFController controller;

  const PDFTextEditor({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF View Layer
        GestureDetector(
          onTapUp: (details) {
            if (controller.isEditingText.value) {
              _handleTapForEditing(context, details.localPosition);
            }
          },
          child: PDFView(
            filePath: controller.document.value!.filePath,
            onViewCreated: (PDFViewController pdfViewController) {
              controller.pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                controller.currentPage.value = page + 1;
                if (total != null) {
                  controller.totalPages.value = total;
                }
              }
            },
            onRender: (pages) {
              if (pages != null) {
                controller.totalPages.value = pages;
              }
            },
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            fitPolicy: FitPolicy.WIDTH,
            pageSnap: true,
          ),
        ),

        // Inline Text Editor Layer
        Obx(() => Stack(
              children: controller.activeTextEdits.map((textEdit) {
                return Positioned(
                  left: textEdit.position.dx,
                  top: textEdit.position.dy,
                  child: InlineTextEditor(
                    initialText: textEdit.text,
                    onSubmitted: (newText) => _updateText(
                      textEdit.pageNumber,
                      textEdit.bounds!,
                      newText,
                    ),
                    style: TextStyle(
                      fontSize: textEdit.fontSize,
                      color: textEdit.color,
                    ),
                    onCancel: () {},
                  ),
                );
              }).toList(),
            )),

        // Edit Mode Indicator
        Positioned(
          top: 16,
          right: 16,
          child: Obx(() => controller.isEditingText.value
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Edit Mode',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : const SizedBox.shrink()),
        ),

        // Edit Mode Toggle Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _toggleEditMode(context),
            child: Obx(() => Icon(
                  controller.isEditingText.value ? Icons.edit_off : Icons.edit,
                )),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTapForEditing(BuildContext context, Offset point) async {
    try {
      if (controller.pdfDocument == null) return;

      final page =
          controller.pdfDocument!.pages[controller.currentPage.value - 1];
      final textExtractor = PdfTextExtractor(controller.pdfDocument!);

      // Calculate tap area bounds
      final tapAreaSize = 50.0;
      final bounds = Rect.fromCenter(
        center: point,
        width: tapAreaSize,
        height: tapAreaSize,
      );

      // Extract text from the current page
      String extractedText = textExtractor.extractText(
        startPageIndex: controller.currentPage.value - 1,
        endPageIndex: controller.currentPage.value - 1,
      );

      if (extractedText.isNotEmpty) {
        controller.startInlineEdit(
          PDFTextEdit(
            text: extractedText,
            position: point,
            bounds: bounds,
            pageNumber: controller.currentPage.value,
            fontSize: controller.currentFontSize,
            color: controller.currentColor,
          ),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to extract text: $e');
    }
  }

  Future<void> _updateText(int pageNumber, Rect bounds, String newText) async {
    try {
      if (controller.pdfDocument == null) return;

      final page = controller.pdfDocument!.pages[pageNumber - 1];
      final pageSize = page.size;
      final scale = Get.size.width / pageSize.width;

      final pdfBounds = Rect.fromLTWH(
        bounds.left / scale,
        bounds.top / scale,
        bounds.width / scale,
        bounds.height / scale,
      );

      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      page.graphics.drawString(
        newText,
        font,
        bounds: pdfBounds,
      );

      await controller.saveChanges();
      await controller.pdfViewController.setPage(pageNumber - 1);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update text: $e');
    }
  }

  void _toggleEditMode(BuildContext context) {
    controller.isEditingText.value = !controller.isEditingText.value;

    final message = controller.isEditingText.value
        ? 'Tap on text to edit'
        : 'Edit mode disabled';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Enhanced InlineTextEditor widget
class InlineTextEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onSubmitted;
  final VoidCallback onCancel;
  final TextStyle style;
  final Rect? bounds;

  const InlineTextEditor({
    Key? key,
    required this.initialText,
    required this.onSubmitted,
    required this.onCancel,
    required this.style,
    this.bounds,
  }) : super(key: key);

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<InlineTextEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late LayerLink _layerLink;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode()..requestFocus();
    _layerLink = LayerLink();

    // Handle focus loss
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.onSubmitted(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: widget.bounds?.width ?? 200,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: widget.style,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: InputBorder.none,
                  ),
                  onFieldSubmitted: widget.onSubmitted,
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
