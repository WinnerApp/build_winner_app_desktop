import 'package:get/get.dart';

import '../controllers/build_parameter_detail_controller.dart';

class BuildParameterDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuildParameterDetailController>(
      () => BuildParameterDetailController(),
    );
  }
}
