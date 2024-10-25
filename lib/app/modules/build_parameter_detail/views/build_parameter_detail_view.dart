import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../controllers/build_parameter_detail_controller.dart';

class BuildParameterDetailView extends GetView<BuildParameterDetailController> {
  const BuildParameterDetailView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打包配置详情'),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, index) {
              return controller.buildParameters[index].buildCell(context);
            },
            separatorBuilder: (context, index) => const TDDivider(),
            itemCount: controller.buildParameters.length,
          ),
        ),
        TDButton(
          text: '立即打包',
          size: TDButtonSize.large,
          type: TDButtonType.fill,
          theme: TDButtonTheme.primary,
          isBlock: true,
          onTap: () => controller.build(),
        ),
      ]),
    );
  }
}
