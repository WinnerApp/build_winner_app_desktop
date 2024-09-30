import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打包页面'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => controller.logout(),
            child: const Text(
              '退出登录',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TDTabBar(
              tabs: const [
                TDTab(
                  text: '测试包',
                ),
                TDTab(
                  text: '正式包',
                ),
              ],
              labelColor: Colors.blue,
              dividerColor: Colors.blue,
              controller: controller.tabController,
              onTap: (p0) {
                controller.isRelease.value = p0 == 1;
              },
            ),
            TDTabBar(
              tabs: const [
                TDTab(
                  text: 'iOS',
                ),
                TDTab(
                  text: 'Android',
                ),
              ],
              labelColor: Colors.blue,
              dividerColor: Colors.blue,
              controller: controller.platformController,
            ),
            TDInput(
              controller: controller.flutterBranchController,
              leftLabel: 'flutter 分支',
              leftLabelStyle: const TextStyle(color: Colors.blue),
              required: true,
            ),
            // TDInput(
            //   controller: controller.buildNameController,
            //   leftLabel: '打包版本',
            //   leftLabelStyle: const TextStyle(color: Colors.blue),
            //   required: true,
            // ),
            TDButton(
              text: '打包',
              size: TDButtonSize.large,
              type: TDButtonType.fill,
              theme: TDButtonTheme.primary,
              isBlock: true,
              onTap: () => controller.build(),
            ),
            const SizedBox(height: 20),
            // Padding(
            //   padding: const EdgeInsets.only(left: 16, right: 16),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         flex: 1,
            //         child: TDSteps(
            //           steps: [
            //             TDStepsItemData(title: '1', content: '2'),
            //             TDStepsItemData(title: '2', content: '3'),
            //           ],
            //         ),
            //       )
            //     ],
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
