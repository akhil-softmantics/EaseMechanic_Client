// lib/utils/pdf_renderer.dart
import 'package:flutter/services.dart';

class PDFRenderer {
  static const platform = MethodChannel('pdf_renderer');
  
  static Future<void> initializeRenderer() async {
    try {
      await platform.invokeMethod('initializeRenderer');
    } catch (e) {
      print('PDF renderer initialization error: $e');
    }
  }
}
