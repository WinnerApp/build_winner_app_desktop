import 'package:get/get.dart';

import '../modules/build_parameter_detail/bindings/build_parameter_detail_binding.dart';
import '../modules/build_parameter_detail/views/build_parameter_detail_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.BUILD_PARAMETER_DETAIL,
      page: () => const BuildParameterDetailView(),
      binding: BuildParameterDetailBinding(),
    ),
  ];
}
