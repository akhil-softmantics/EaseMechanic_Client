// lib/widgets/annotation_widget.dart
import 'package:flutter/material.dart';

import '../../models/pdfFileModel.dart';


class AnnotationWidget extends StatelessWidget {
  final PDFAnnotation annotation;

  const AnnotationWidget({
    Key? key,
    required this.annotation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (annotation.type) {
      case AnnotationType.drawing:
        return CustomPaint(
          painter: DrawingPainter(
            points: annotation.points,
            color: annotation.color,
          ),
        );
      case AnnotationType.highlight:
        return Container(
          color: annotation.color.withOpacity(0.3),
        );
      case AnnotationType.underline:
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: annotation.color,
                width: 2,
              ),
            ),
          ),
        );
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  DrawingPainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}