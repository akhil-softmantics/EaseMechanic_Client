// lib/widgets/editing_overlay.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            // Regular text edits
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
            
            // Active inline text editors
            ...controller.activeTextEdits.map((textEdit) {
              return Positioned(
                left: textEdit.position.dx,
                top: textEdit.position.dy,
                child: InlineTextEditor(
                  initialText: textEdit.text,
                  onSubmitted: (newText) {
                    if (textEdit.bounds != null) {
                      controller.updateText(
                        textEdit.pageNumber,
                        textEdit.bounds!,
                        newText,
                      );
                      controller.activeTextEdits.remove(textEdit);
                    }
                  },
                  onCancel: () {
                    controller.activeTextEdits.remove(textEdit);
                    controller.update();
                  },
                  style: TextStyle(
                    fontSize: textEdit.fontSize,
                    color: textEdit.color,
                  ),
                ),
              );
            }),

            // Annotations
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

class InlineTextEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onSubmitted;
  final VoidCallback onCancel;
  final TextStyle style;

  const InlineTextEditor({
    Key? key,
    required this.initialText,
    required this.onSubmitted,
    required this.onCancel,
    required this.style,
  }) : super(key: key);

  @override
  State<InlineTextEditor> createState() => _InlineTextEditorState();
}

class _InlineTextEditorState extends State<InlineTextEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode()..requestFocus();
    
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                style: widget.style,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: InputBorder.none,
                ),
                onFieldSubmitted: widget.onSubmitted,
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
    );
  }
}
