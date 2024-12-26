import 'package:flutter/material.dart';

import '../../../../../models/pdfFileModel.dart';
import '../../../../widgets/annonation_widget.dart';

class AnnotationWidget extends StatelessWidget {
  final PDFAnnotation annotation;

  const AnnotationWidget({
    Key? key,
    required this.annotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (annotation.type) {
      case AnnotationType.highlight:
        return Container(
          width: 100,
          height: 20,
          color: annotation.color.withOpacity(0.3),
        );
      case AnnotationType.drawing:
        return CustomPaint(
          painter: DrawingPainter(
            points: annotation.points,
            color: annotation.color,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
