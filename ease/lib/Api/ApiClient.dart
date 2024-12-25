import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ease/core/appBaseUrl.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<bool> isValidPDF(File file) async {
    try {
      if (!file.existsSync()) return false;
      
      final bytes = await file.readAsBytes();
      if (bytes.length < 4) return false;
      
      // Check PDF magic number (%PDF)
      return bytes[0] == 0x25 && 
             bytes[1] == 0x50 && 
             bytes[2] == 0x44 && 
             bytes[3] == 0x46;
    } catch (e) {
      print('PDF validation error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> translatePdf({
    required File pdfFile,
    required String targetLanguage,
  }) async {
    try {
      // Validate PDF first
      if (!await isValidPDF(pdfFile)) {
        return {
          'success': false,
          'error': 'Invalid or corrupted PDF file'
        };
      }

      // Check file size (e.g., limit to 10MB)
      final fileSize = await pdfFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return {
          'success': false,
          'error': 'PDF file size exceeds 10MB limit'
        };
      }

      // Read the PDF file and convert to base64
      final bytes = await pdfFile.readAsBytes();
      final base64Pdf = base64Encode(bytes);

      // Print the first few characters of base64 string for debugging
      print('Base64 PDF preview: ${base64Pdf.substring(0, min(100, base64Pdf.length))}...');

      // Prepare the request
      final response = await http.post(
        Uri.parse('${AppUrl.baseUrl}/convertfile/language'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'pdfBase64': base64Pdf,
          'targetLanguage': targetLanguage,
          'preserveFormatting': true  // Add this if your API expects it
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['translatedPdf'] == null) {
          return {
            'success': false,
            'error': 'No translated PDF in response'
          };
        }

        try {
          // Convert base64 PDF back to bytes and save to file
          final translatedPdfBytes = base64Decode(responseData['translatedPdf']);
          
          // Create a unique filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final outputFile = File(
            '${pdfFile.parent.path}/translated_$timestamp.pdf'
          );
          
          await outputFile.writeAsBytes(translatedPdfBytes);

          // Validate the created file
          if (!await isValidPDF(outputFile)) {
            outputFile.deleteSync();
            return {
              'success': false,
              'error': 'Generated PDF is invalid'
            };
          }

          return {
            'success': true,
            'file': outputFile,
            'sourceLanguage': responseData['sourceLanguage'],
            'message': responseData['message'],
          };
        } catch (e) {
          print('Error processing translated PDF: $e');
          return {
            'success': false,
            'error': 'Failed to process translated PDF'
          };
        }
      } else {
        print('Error response body: ${response.body}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to translate PDF'
        };
      }
    } catch (e, stackTrace) {
      print('Translation error: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}