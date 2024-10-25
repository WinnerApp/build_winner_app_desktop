import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class BuildParameterDetailController extends GetxController {
  late List<BuildParameterType> buildParameters;

  @override
  void onInit() {
    super.onInit();
    buildParameters = Get.arguments;
  }

  build() {
    Map<String, String> config = {};
    for (var i = 0; i < buildParameters.length; i++) {
      final parameter = buildParameters[i];
      config[parameter.name] = parameter.buildValue;
    }
    Get.back(result: config);
  }
}

abstract class BuildParameterType {
  final String name;
  final String? description;
  final String? defaultValue;

  const BuildParameterType({
    required this.name,
    required this.description,
    required this.defaultValue,
  });

  Widget buildCell(BuildContext context);

  String get title => '${description ?? name}($name)';

  updateDefaultValue(String defaultValue) {}

  String get buildValue;
}

class BuildParameterChoose extends BuildParameterType {
  final value = Rxn<String>();
  final List<String> values;
  BuildParameterChoose({
    required super.name,
    required super.description,
    required super.defaultValue,
    required this.values,
  }) {
    value.value = defaultValue;
  }

  @override
  Widget buildCell(BuildContext context) {
    return Obx(() => TDCell(
          title: title,
          description: value.value ?? '请选择',
          arrow: true,
          onClick: (cell) {
            final initIndex = values.indexOf(value.value!);
            TDPicker.showMultiPicker(
              context,
              title: '请选择$title',
              initialIndexes: [initIndex],
              onConfirm: (data) {
                int index = data[0];
                value.value = values[index];
                Navigator.of(context).pop();
              },
              data: [values],
            );
          },
        ));
  }

  @override
  updateDefaultValue(String defaultValue) {
    value.value = defaultValue;
  }

  @override
  String get buildValue => value.value ?? '';
}

class BuildParameterInput extends BuildParameterType {
  TextEditingController controller;

  BuildParameterInput({
    required super.name,
    required super.description,
    required super.defaultValue,
  }) : controller = TextEditingController(text: defaultValue);

  @override
  TDCell buildCell(BuildContext context) {
    return TDCell(
      title: title,
      descriptionWidget: TDInput(
        controller: controller,
        decoration: BoxDecoration(
          border: Border.all(color: TDTheme.of(context).grayColor4),
        ),
      ),
    );
  }

  @override
  updateDefaultValue(String defaultValue) {
    controller.text = defaultValue;
  }

  @override
  String get buildValue => controller.text;
}

class BuildParameterSwitch extends BuildParameterType {
  final value = false.obs;
  BuildParameterSwitch({
    required super.name,
    required super.description,
    required super.defaultValue,
  }) {
    value.value = defaultValue == 'true';
  }

  @override
  Widget buildCell(BuildContext context) {
    return ObxValue<RxBool>(
      (p0) => TDCell(
        title: title,
        rightIconWidget: TDSwitch(
          isOn: p0.value,
          onChanged: p0,
        ),
      ),
      value,
    );
  }

  @override
  updateDefaultValue(String defaultValue) {
    value.value = defaultValue == 'true';
  }

  @override
  String get buildValue => value.value ? 'true' : 'false';
}
