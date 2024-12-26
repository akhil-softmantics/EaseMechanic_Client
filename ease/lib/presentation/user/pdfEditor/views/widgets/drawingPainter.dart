import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/pdfEditor_controller.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}


// lib/widgets/pdf_drawing_overlay.dart
class PDFDrawingOverlay extends StatelessWidget {
  const PDFDrawingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PDFController>(
      builder: (controller) {
        if (!controller.isDrawingMode.value) return const SizedBox.shrink();

        return GestureDetector(
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final point = box.globalToLocal(details.globalPosition);
            controller.addDrawingPoint(point);
          },
          child: CustomPaint(
            painter: DrawingPainter(points: controller.drawingPoints),
            child: Container(),
          ),
        );
      },
    );
  }
}