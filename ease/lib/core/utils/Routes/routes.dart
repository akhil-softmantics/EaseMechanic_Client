import 'dart:core';

import 'package:ease/presentation/user/homePage/bindings/home_page_binding.dart';
import 'package:ease/presentation/user/homePage/views/homePage.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String homePage = '/';
  static const pdfScreen = '/pdf';
  static List<GetPage> pages = [
    GetPage(
        name: homePage,
        page: () => HomePage(),
        binding: HomePageBinding())
    // GetPage(name: pdfScreen, page: page)
  ];
}
