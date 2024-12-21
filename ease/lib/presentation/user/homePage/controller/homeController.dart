import 'dart:async';
import 'dart:io';

import 'package:ease/Api/ApiClient.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HomeController extends GetxController {
  final RxString selectedFromLanguage = 'English'.obs;
  final RxString selectedToLanguage = 'Spanish'.obs;
  final RxBool isFileSelected = false.obs;
  final RxBool isLoading = false.obs;
  final RxString fileName = ''.obs;

  // Add this variable to store the selected file path
  final Rx<String?> selectedFilePath = Rx<String?>(null);

  // Language detector instance
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  final _filePickerLock = false.obs;

  // Map of language codes to display names
  final Map<String, String> languageCodes = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ml': 'malayalam'
    // Add more languages as needed
  };

  @override
  void onInit() {
    super.onInit();
    FilePicker.platform.clearTemporaryFiles();
  }

  void setFromLanguage(String lang) => selectedFromLanguage.value = lang;
  void setToLanguage(String lang) => selectedToLanguage.value = lang;

  void swapLanguages() {
    final temp = selectedFromLanguage.value;
    selectedFromLanguage.value = selectedToLanguage.value;
    selectedToLanguage.value = temp;
  }

  void clearSelectedFile() {
    isFileSelected.value = false;
    fileName.value = '';
    selectedFilePath.value = null;
    FilePicker.platform.clearTemporaryFiles();
  }

  Future<String?> detectPDFLanguage(String filePath) async {
    try {
      // Load the PDF document
      final List<int> bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from the first few pages (for better accuracy)
      String extractedText = '';
      final int pagesToCheck =
          document.pages.count < 3 ? document.pages.count : 3;

      // Create a single PdfTextExtractor instance for the document
      final textExtractor = PdfTextExtractor(document);

      // Extract text from each page
      for (int i = 0; i < pagesToCheck; i++) {
        extractedText +=
            textExtractor.extractText(startPageIndex: i, endPageIndex: i);
        print(
            'the extracted text : ---------------------------------------------------$extractedText');
        if (extractedText.length > 1000) break;
      }

      document.dispose();

      if (extractedText.trim().isEmpty) {
        print('No text could be extracted from the PDF');
        return null;
      }

      final String languageCode =
          await _languageIdentifier.identifyLanguage(extractedText);
      print(
          'the extracted language name : ------------------------------------------- $languageCode');
      return languageCodes[languageCode] ?? 'English';
    } catch (e) {
      print('Error detecting language: $e');
      return null;
    }
  }

  Future<void> selectFile() async {
    clearSelectedFile();

    if (_filePickerLock.value || isLoading.value) {
      print('File picker is already active or loading');
      return;
    }

    try {
      _filePickerLock.value = true;
      isLoading.value = true;

      await FilePicker.platform.clearTemporaryFiles();

      final result = await FilePicker.platform
          .pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
        allowCompression: false,
        lockParentWindow: true,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('File picking timed out');
        },
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.name.toLowerCase().endsWith('.pdf')) {
        fileName.value = result.files.first.name;
        selectedFilePath.value = result.files.first.path; // Store the file path
        isFileSelected.value = true;

        final detectedLanguage =
            await detectPDFLanguage(result.files.first.path!);
        if (detectedLanguage != null) {
          setFromLanguage(detectedLanguage);
          print('Detected language: $detectedLanguage');
        }

        print('File selected successfully: ${fileName.value}');
      }
    } catch (e) {
      print('Error picking file: $e');
      Get.snackbar(
        'Error',
        'Failed to pick file. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      _filePickerLock.value = false;
    }
  }

  Future<void> convertPDF() async {
    if (!isFileSelected.value || selectedFilePath.value == null) {
      Get.snackbar(
        'Error',
        'Please select a PDF file first',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final file = File(selectedFilePath.value!);
      final response = await ApiClient.translatePdf(
        pdfFile: file,
        targetLanguage: selectedToLanguage.value.toLowerCase().substring(0, 2),
      );

      if (response['success']) {
        Get.snackbar(
          'Success',
          'PDF translated successfully!',
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        final translatedFile = response['file'] as File;
        print(
            'the translated pdf is : -------------------------------------------$translatedFile');

        // Show share dialog
        await shareTranslatedPDF(translatedFile);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to convert PDF: $e',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> shareTranslatedPDF(File translatedFile) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(translatedFile.path)],
        text: 'Translated PDF',
      );

      if (result.status == ShareResultStatus.success) {
        print('File shared successfully');
      } else {
        print('File sharing canceled or failed');
      }
    } catch (e) {
      print('Error sharing file: $e');
      Get.snackbar(
        'Error',
        'Failed to share PDF',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    _languageIdentifier.close();
    FilePicker.platform.clearTemporaryFiles();
    super.onClose();
  }
}
