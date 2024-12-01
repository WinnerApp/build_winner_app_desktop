import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
            builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('登录页面'),
                    centerTitle: true,
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(80.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TDInput(
                                  controller: controller.serverHostController,
                                  leftLabel: '服务器地址',
                                ),
                              ),
                              // Expanded(
                              //   flex: 1,
                              //   child: TDInput(
                              //     controller: controller.serverPortController,
                              //     leftLabel: '服务器端口',
                              //   ),
                              // ),
                            ],
                          ),
                          TDInput(
                            controller: controller.usernameController,
                            leftLabel: '用户名',
                          ),
                          TDInput(
                            controller: controller.passwordController,
                            leftLabel: '密码',
                          ),
                          TDInput(
                            controller: controller.buildVersionController,
                            leftLabel: '版本号',
                          ),
                          const SizedBox(height: 50),
                          TDButton(
                            onTap: () => controller.login(context),
                            size: TDButtonSize.large,
                            type: TDButtonType.fill,
                            theme: TDButtonTheme.primary,
                            isBlock: true,
                            text: '登录',
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
      ],
    );
  }
}
