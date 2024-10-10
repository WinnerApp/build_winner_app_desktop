import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

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
            Obx(() => TDButton(
                  text: '打包',
                  size: TDButtonSize.large,
                  type: TDButtonType.fill,
                  theme: TDButtonTheme.primary,
                  isBlock: true,
                  onTap: () {
                    SmartDialog.showLoading();
                    controller.build(context);
                    SmartDialog.dismiss();
                  },
                  disabled: !controller.enableBuild.value,
                )),
            const SizedBox(height: 20),
            Expanded(
                child: ListView(
              children: [
                Obx(() => TDCollapse(
                      style: TDCollapseStyle.block,
                      expansionCallback: (int index, bool isExpanded) {
                        if (index == 0) {
                          controller.isExpandBuildList.value = !isExpanded;
                        } else if (index == 1) {
                          controller.isExpandQueueList.value = !isExpanded;
                        }
                      },
                      children: [
                        TDCollapsePanel(
                          isExpanded: controller.isExpandBuildList.value,
                          headerBuilder: (context, isExpanded) {
                            final count = controller.buildNameList.length;
                            return Text('当前正在构建项目($count)');
                          },
                          body: TDCellGroup(
                              cells: controller.buildNameList
                                  .map((element) => TDCell(
                                        title: 'meta_winner_app2',
                                        style: TDCellStyle(
                                            backgroundColor:
                                                Colors.green.shade100),
                                      ))
                                  .toList()),
                        ),
                        TDCollapsePanel(
                          isExpanded: controller.isExpandQueueList.value,
                          headerBuilder: (context, isExpanded) {
                            final count = controller.queueList.length;
                            return Text('当前等待构建任务($count)');
                          },
                          body: TDCellGroup(
                              cells: controller.queueList
                                  .map((element) => TDCell(
                                        title: '${element.name}(${element.id})',
                                        style: TDCellStyle(
                                            backgroundColor:
                                                Colors.grey.shade100),
                                      ))
                                  .toList()),
                        ),
                      ],
                    )),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
