import 'dart:async';
import 'dart:convert';
import 'package:build_winner_app_desktop/app/common/app_storage.dart';
import 'package:build_winner_app_desktop/app/modules/build_parameter_detail/controllers/build_parameter_detail_controller.dart';
import 'package:build_winner_app_desktop/app/routes/app_pages.dart';
import 'package:build_winner_app_desktop/common/define.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController;

  /// 选择打包平台
  late TabController platformController;

  /// Flutter打包分支
  TextEditingController flutterBranchController =
      TextEditingController(text: 'dev_2.0');

  // /// 打包的版本号
  // TextEditingController buildNameController =
  //     TextEditingController(text: '1.1.5');

  /// 当前是否打正式包
  var isRelease = false.obs;

  /// 是否允许打包
  final enableBuild = true.obs;

  String get host => AppStorage.host.read() ?? '';
  // String get port => AppStorage.port.read() ?? '';

  /// 当前是否展开[构建项目列表]
  final isExpandBuildList = false.obs;

  /// 是否展开[等待队列]
  final isExpandQueueList = false.obs;

  /// 是否展示构建历史
  final isExpandBuildHistory = false.obs;

  /// 当前正在构建项目名称列表
  final buildNameList = <String>[].obs;

  /// 当前队列的任务列表
  final queueList = <QueueData>[].obs;

  Timer? _timer;

  /// 是否全部渠道
  final isAllChannel = false.obs;

  List<BuildParameterType> _allBuildParameters = [];
  final showBuildParameters = <BuildParameterType>[].obs;

  final Map<String, String> _debugConfig = {};
  final Map<String, String> _releaseConfig = {};

  /// 当前打包历史
  final buildHistorys = <BuildHistoryData>[].obs;

  final isLoadHistory = true.obs;

  /// 当前打包的配置
  Map<String, String> get currentBuildConfig {
    var config = isRelease.value ? _releaseConfig : _debugConfig;
    config['PLATFROM'] = platformController.index == 0 ? 'ios' : 'android';
    config['BUILD_NUMBER'] = buildNumber;
    for (var element in showBuildParameters) {
      config[element.name] = element.buildValue;
    }
    final buildName = config['BUILD_NAME'] ?? '';
    config['BUILD_NAME'] = AppStorage.version.read<String>() ?? buildName;
    return config;
  }

  String get buildNumber =>
      "${DateTime.now().millisecondsSinceEpoch}".substring(0, 10);

  @override
  onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    platformController = TabController(length: 2, vsync: this);

    init();
  }

  @override
  onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 初始化当前任务状态
  Future<void> init([bool showLoadiong = true]) async {
    if (showLoadiong) SmartDialog.showLoading();
    _loadData();
    final config = await getJobConfig('meta_winner_app2');
    _allBuildParameters =
        JSON(config)['property'][0]['parameterDefinitions'].listValue.map((e) {
      final defaultValue = JSON(e)['defaultParameterValue']['value'].string;
      final description = JSON(e)['description'].string;
      final name = JSON(e)['name'].stringValue;
      final type = JSON(e)['type'].stringValue;
      final allValueItems = JSON(e)['allValueItems']['values'].listValue;
      final choices =
          JSON(e)['choices'].listValue.map((e) => e.toString()).toList();
      if (type == 'GitParameterDefinition') {
        return BuildParameterChoose(
          name: name,
          description: description,
          defaultValue: defaultValue,
          values:
              allValueItems.map((e) => JSON(e)['value'].stringValue).toList(),
        );
      } else if (type == 'ChoiceParameterDefinition') {
        return BuildParameterChoose(
          name: name,
          description: description,
          defaultValue: defaultValue,
          values: choices,
        );
      } else if (type == 'TextParameterDefinition' ||
          type == 'StringParameterDefinition') {
        return BuildParameterInput(
          name: name,
          description: description,
          defaultValue: defaultValue,
        );
      } else if (type == 'BooleanParameterDefinition') {
        return BuildParameterSwitch(
          name: name,
          description: description,
          defaultValue: defaultValue,
        );
      } else {
        throw UnimplementedError();
      }
    }).toList();

    if (showLoadiong) SmartDialog.dismiss();

    showBuildParameters.value = _allBuildParameters
        .map((element) => ["BRANCH", "UNITY_BRANCH_NAME"].contains(element.name)
            ? element
            : null)
        .whereType<BuildParameterType>()
        .toList();

    for (var i = 0; i < _allBuildParameters.length; i++) {
      final parameter = _allBuildParameters[i];
      _debugConfig[parameter.name] = parameter.defaultValue ?? '';
      _releaseConfig[parameter.name] = parameter.defaultValue ?? '';
      if (parameter.name == 'IS_STORE') {
        _releaseConfig[parameter.name] = 'true';
      } else if (parameter.name == "ZEALOT_CHANNEL_KEY") {
        _releaseConfig[parameter.name] = '';
      } else if (parameter.name == "FORCE_BUILD") {
        _releaseConfig[parameter.name] = 'true';
      } else if (parameter.name == "SEND_LOG") {
        _releaseConfig[parameter.name] = 'false';
      }
    }

    final buildIds = JSON(config)["builds"]
        .listValue
        .map((e) => JSON(e)['number'].intValue)
        .toList();
    final historys = <BuildHistoryData>[];
    for (var element in buildIds.sublist(0, 15)) {
      try {
        final data =
            await getBuildDetail('meta_winner_app2', element.toString());
        historys.add(BuildHistoryData(id: element, data: data ?? ''));
      } catch (e, s) {
        logger.e(e.toString(), error: e, stackTrace: s);
      }
    }

    buildHistorys.value = historys;
    isLoadHistory.value = false;
    update();
  }

  _loadData() async {
    /// 查询当前任务状态
    final queueData = await getQueue();
    queueList.value = JSON(queueData)['items']
        .listValue
        .map((e) => QueueData(
            id: JSON(e)['id'].intValue,
            name: JSON(e)['task']['name'].stringValue))
        .toList();

    final projects = await getProjects();
    buildNameList.value = JSON(projects)['jobs']
        .listValue
        .where((e) {
          final color = JSON(e)['color'].stringValue;
          return color.endsWith('_anime');
        })
        .map((e) => JSON(e)['name'].stringValue)
        .toList();
    update();
  }

  /// 检测当前是否还有进行中的任务

  /// 退出登录
  Future<void> logout() async {
    Get.offNamed(Routes.LOGIN);
  }

  /// 执行打包
  Future<void> build(Map<String, String> config) async {
    var androidChannel = config["androidChannel"]!;
    var allowOtherChannel = config["ALLOW_OTHER_CHANNEL"] ?? 'true';
    var platfrom = config["PLATFROM"]!;
    var isStore = config["IS_STORE"]!;

    Map<String, dynamic> buildConfig = {};
    for (var element in _allBuildParameters) {
      buildConfig[element.name] = config[element.name];
    }

    // if (upload == "true") {
    //   /// 合并代码到release2.0
    //   await buildWithParameters('merge_release', {
    //     'BRANCH': branch,
    //   });
    // }

    Future<void> buildApp(
        {String channel = 'Winner', String skipUnity = 'false'}) async {
      var config = {...buildConfig};
      config['androidChannel'] = channel;
      if (config.keys.contains('skipUnity')) {
        config['skipUnity'] = skipUnity;
      }
      await _buildApp(config);
    }

    await buildApp(channel: androidChannel);

    if (allowOtherChannel == "true" &&
        isStore == 'true' &&
        platfrom == 'android') {
      final channels = [
        'Winner',
        'Tencent',
        'Huawei',
        'Xiaomi',
        'Oppo',
        'Meizu',
        'Honor',
        'Samsung',
        'Vivo'
      ];
      for (var i = 0; i < channels.length; i++) {
        final otherChannel = channels[i];
        if (otherChannel == androidChannel) continue;
        await buildApp(channel: otherChannel, skipUnity: 'true');
      }
    }
  }

  Future<void> _buildApp(Map<String, dynamic> config) async {
    await buildWithParameters('meta_winner_app2', config);
  }

  Future<void> buildWithParameters(
      String jobName, Map<String, dynamic> data) async {
    String host = AppStorage.host.read() ?? '';
    final url = await getBuildWithParametersUrl(jobName);
    final username = GetStorage().read('username');
    final password = GetStorage().read('password');
    final crumb = await getCrumb(host, username, password);
    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    dio.options.headers['Authorization'] = authHeader;
    if (crumb != null) {
      final parts = crumb.split(':');
      dio.options.headers[parts[0]] = parts[1];
    }
    final response = await dio.post(url, queryParameters: data);
    if (response.statusCode == 201) {
      SmartDialog.showToast('任务启动成功');
    } else {
      throw Exception(response.data.toString());
    }
  }

  Future<String> getBuildWithParametersUrl(String jobName) async {
    String host = AppStorage.host.read() ?? '';
    return 'http://$host/job/$jobName/buildWithParameters';
  }

  /// 获取最新的任务ID
  Future<String?> getLatestBuildId(String jobName) async {
    final url = 'http://$host/job/$jobName/lastBuild/buildNumber';
    try {
      final response = await dio.get(url);
      return response.data;
    } catch (e, s) {
      SmartDialog.showToast(e.toString(), displayTime: 3.seconds);
      logger.e(e.toString(), error: e, stackTrace: s);
      return null;
    }
  }

  /// 获取当前任务详情
  Future<String?> getBuildDetail(String jobName, String buildId) async {
    final url = 'http://$host/job/$jobName/$buildId/api/json?pretty=true';
    try {
      final response = await dio.get(url);
      return JSON(response.data).string;
    } catch (e, s) {
      SmartDialog.showToast(e.toString(), displayTime: 3.seconds);
      logger.e(e.toString(), error: e, stackTrace: s);
      return null;
    }
  }

  /// 查询当前队列任务状态
  Future<dynamic> getQueue() async {
    final url = 'http://$host/queue/api/json';
    final response = await dio.get(url);
    return response.data;
  }

  /// 查询当前Jenkins项目状态
  Future<dynamic> getProjects() async {
    final url = 'http://$host/api/json';
    final response = await dio.get(url);
    return response.data;
  }

  /// 获取当前打包工程的配置
  Future<dynamic> getJobConfig(String jobName) async {
    final url = 'http://$host/job/$jobName/api/json?pretty=true';
    try {
      final response = await dio.get(url);
      return response.data;
    } catch (e, s) {
      SmartDialog.showToast(e.toString(), displayTime: 3.seconds);
      logger.e(e.toString(), error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> toBuildParameterDetail(Map<String, String> config) async {
    var parameters = [..._allBuildParameters];
    parameters.add(
      BuildParameterSwitch(
        name: 'ALLOW_OTHER_CHANNEL',
        description: '是否允许打其他渠道',
        defaultValue:
            config['IS_STORE'] == 'true' && config['PLATFROM'] == 'android'
                ? 'true'
                : 'false',
      ),
    );
    for (var i = 0; i < parameters.length; i++) {
      final parameter = parameters[i];
      var value = config[parameter.name];
      if (parameter.name == 'BUILD_NAME') {
        value = AppStorage.version.read() ?? value;
      }
      if (value != null) {
        parameter.updateDefaultValue(value);
      }
    }
    final result = await Get.toNamed(
      Routes.BUILD_PARAMETER_DETAIL,
      arguments: parameters,
    );
    if (result == null) return;
    build(result);
  }

  openHistoryBuildDetail(BuildHistoryData element) =>
      toBuildParameterDetail(getBuildConfig(element));

  Map<String, String> getBuildConfig(BuildHistoryData element) {
    Map<String, String> config = {};
    final action = JSON(element.data)['actions'].listValue.firstWhereOrNull(
        (element) =>
            JSON(element)["_class"].stringValue ==
            "hudson.model.ParametersAction");
    final parameters = JSON(action)['parameters'].listValue;
    for (var element in parameters) {
      config[JSON(element)['name'].stringValue] =
          JSON(element)['value'].stringValue;
    }
    return config;
  }

  // 获取 CSRF 令牌
  Future<String?> getCrumb(
    String jenkinsUrl,
    String username,
    String password,
  ) async {
    final dio = Dio();
    final authHeader =
        'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    dio.options.headers['Authorization'] = authHeader;
    final response = await dio.get('http://$jenkinsUrl/crumbIssuer/api/json');
    if (response.statusCode == 200) {
      final jsonData = response.data;
      return '${jsonData['crumbRequestField']}:${jsonData['crumb']}';
    } else {
      throw Exception('获取 CSRF 令牌失败');
    }
  }
}

/// 队列的数据
class QueueData {
  /// 队列的ID
  final int id;

  /// 队列的名称
  final String name;

  const QueueData({required this.id, required this.name});
}

/// 打包历史数据
class BuildHistoryData {
  /// 任务ID
  final int id;
  final String data;

  const BuildHistoryData({
    required this.id,
    required this.data,
  });
}
