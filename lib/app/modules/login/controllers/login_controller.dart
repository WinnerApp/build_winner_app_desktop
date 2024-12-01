import 'package:build_winner_app_desktop/app/common/app_storage.dart';
import 'package:build_winner_app_desktop/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class LoginController extends GetxController {
  /// 服务器地址
  final serverHostController = TextEditingController();

  /// 服务器端口
  final serverPortController = TextEditingController();

  /// 用户名输入框
  final usernameController = TextEditingController();

  /// 密码输入框
  final passwordController = TextEditingController();

  /// 打包版本号
  final buildVersionController = TextEditingController();

  @override
  onInit() {
    super.onInit();

    serverHostController.text = AppStorage.host.read() ?? '';
    // serverPortController.text = AppStorage.port.read() ?? '';

    usernameController.text = AppStorage.username.read() ?? '';
    passwordController.text = AppStorage.password.read() ?? '';

    buildVersionController.text = AppStorage.version.read() ?? '';
  }

  /// 进行登录
  Future<void> login(BuildContext context) async {
    final serverHost = serverHostController.text;
    final serverPort = serverPortController.text;
    final username = usernameController.text;
    final password = passwordController.text;
    final version = buildVersionController.text;

    if (serverHost.isEmpty ||
        serverPort.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      TDToast.showFail('请输入完整信息', context: context);
      return;
    }

    await Future.wait([
      AppStorage.host.write(serverHost),
      AppStorage.username.write(username),
      AppStorage.password.write(password),
      AppStorage.version.write(version),
    ]);

    Get.toNamed(Routes.HOME);
  }
}
