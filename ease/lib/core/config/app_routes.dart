import 'package:ease/presentation/customer/authentication/signup/bindings/signupBinding.dart';
import 'package:ease/presentation/customer/authentication/signup/views/signupScreen.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String signupScreen = '/signupScreen';
  static List<GetPage> pages = [
    GetPage(
        name: signupScreen,
        page: () => const SignupScreen(),
        binding: SignupBinding())
  ];
}
