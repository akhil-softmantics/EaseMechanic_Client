import 'package:flutter/services.dart';

class PDFRenderer {
  static const platform = MethodChannel('pdf_renderer');
  static bool _isInitialized = false;

  static Future<void> initializeRenderer() async {
    try {
      await platform.invokeMethod('initializeRenderer');
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      print('PDF renderer initialization error: $e');
      throw e;
    }
  }

  static Future<void> closeRenderer() async {
    if (!_isInitialized) return;
    
    try {
      await platform.invokeMethod('closeRenderer');
    } finally {
      _isInitialized = false;
    }
  }

  static Future<Map<String, dynamic>> openDocument(String path) async {
    if (!_isInitialized) {
      await initializeRenderer();
    }

    try {
      final result = await platform.invokeMethod('openDocument', {'path': path});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      await closeRenderer();
      throw e;
    }
  }
}