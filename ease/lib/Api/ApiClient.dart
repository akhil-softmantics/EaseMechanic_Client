import 'dart:convert';
import 'dart:io';
import 'package:ease/core/appBaseUrl.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static Future<Map<String, dynamic>> translatePdf({
    required File pdfFile,
    required String targetLanguage,
  }) async {
    try {
      // Read the PDF file and convert to base64
      final bytes = await pdfFile.readAsBytes();
      final base64Pdf = base64Encode(bytes);

      // Prepare the request
      final response = await http.post(
        Uri.parse('${AppUrl.baseUrl}/convertfile/language'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pdfBase64': base64Pdf,
          'targetLanguage': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Convert base64 PDF back to bytes and save to file
        final translatedPdfBytes = base64Decode(responseData['translatedPdf']);
        final outputFile = File(
            '${pdfFile.parent.path}/translated_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await outputFile.writeAsBytes(translatedPdfBytes);

        return {
          'success': true,
          'file': outputFile,
          'sourceLanguage': responseData['sourceLanguage'],
          'message': responseData['message'],
        };
      } else {
        throw Exception('Failed to translate PDF: ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
