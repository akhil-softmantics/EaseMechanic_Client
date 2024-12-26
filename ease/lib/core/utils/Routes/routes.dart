import 'dart:core';

import 'package:ease/presentation/user/homePage/bindings/home_page_binding.dart';
import 'package:ease/presentation/user/homePage/views/homePage.dart';
import 'package:ease/presentation/user/pdfEditor/bindings/pdfEditor_bindings.dart';
import 'package:ease/presentation/user/pdfEditor/views/pdfPickerView.dart';
import 'package:get/get.dart';

import '../../../presentation/user/pdfEditor/views/widgets/pdfEditorView.dart';

class AppRoutes {
  static const String homePage = '/';
  static const pdfScreen = '/pdf';
  static const pdfEdit = '/pdfEdit';
  static const pdfEditView = '/pdfEditView';
  static List<GetPage> pages = [
    GetPage(name: homePage, page: () => HomePage(), binding: HomePageBinding()),
    GetPage(
        name: pdfEdit,
        page: () => PDFPickerView(),
        binding: PdfEditorBindings()),
    GetPage(
        name: pdfEditView,
        page: () => PDFEditorView(),
        binding: PdfEditorBindings())
    // GetPage(name: pdfScreen, page: page)
  ];
}
