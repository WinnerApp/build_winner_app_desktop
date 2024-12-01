import 'package:darty_json_safe/darty_json_safe.dart';
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
            Obx(() {
              return Column(
                children: controller.showBuildParameters
                    .map((element) => element.buildCell(context))
                    .toList(),
              );
            }),
            TDCellGroup(cells: [
              TDCell(
                title: '详细配置',
                arrow: true,
                onClick: (cell) {
                  controller
                      .toBuildParameterDetail(controller.currentBuildConfig);
                },
              )
            ]),
            Obx(() => TDButton(
                  text: '打包',
                  size: TDButtonSize.large,
                  type: TDButtonType.fill,
                  theme: TDButtonTheme.primary,
                  isBlock: true,
                  onTap: () async {
                    SmartDialog.showLoading();
                    await controller.build(controller.currentBuildConfig);
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
                        } else if (index == 2) {
                          controller.isExpandBuildHistory.value = !isExpanded;
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
                        TDCollapsePanel(
                          isExpanded: controller.isExpandBuildHistory.value,
                          headerBuilder: (context, isExpanded) {
                            return const Text('历史构建');
                          },
                          body: TDCellGroup(
                              cells: controller.buildHistorys
                                  .map((element) => TDCell(
                                        titleWidget: _buildCellTitle(element),
                                        style: TDCellStyle(
                                            backgroundColor:
                                                Colors.grey.shade100),
                                        arrow: true,
                                        rightIconWidget:
                                            _buildCellRight(element),
                                        descriptionWidget:
                                            _buildCellDescription(element),
                                        onClick: (cell) => controller
                                            .openHistoryBuildDetail(element),
                                      ))
                                  .toList()),
                        )
                      ],
                    )),
              ],
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildCellTitle(BuildHistoryData element) {
    bool building = JSON(element.data)['building'].boolValue;
    final result = JSON(element.data)['result'].stringValue;
    late Widget icon;
    if (result == 'SUCCESS') {
      icon = const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    } else if (result == "FAILURE") {
      icon = const Icon(
        Icons.highlight_off,
        color: Colors.red,
      );
    } else if (result == "ABORTED") {
      icon = const Icon(
        Icons.do_not_disturb,
        color: Colors.grey,
      );
    } else if (building) {
      icon = const Icon(
        Icons.radio_button_unchecked,
        color: Colors.blue,
      );
    } else {
      icon = Container();
    }
    return Row(
      children: [
        icon,
        Text(element.id.toString()),
        if (building) const Text('(打包中....)')
      ],
    );
  }

  Widget _buildCellRight(BuildHistoryData element) {
    final result = JSON(element.data)['timestamp'].intValue;
    return Text(DateTime.fromMillisecondsSinceEpoch(result).toIso8601String());
  }

  Widget _buildCellDescription(BuildHistoryData element) {
    final config = controller.getBuildConfig(element);
    final displayNames = [
      "PLATFROM",
      "BUILD_NAME",
      "BRANCH",
      "UNITY_BRANCH_NAME",
      "IS_STORE",
      "androidChannel",
      "BUILD_NUMBER"
    ];
    return Row(
      children: displayNames.map((e) {
        final value = config[e];
        return TDTag(
          "$e:$value",
          theme: TDTagTheme.primary,
          isOutline: true,
          shape: TDTagShape.round,
        );
      }).toList(),
    );
  }
}
