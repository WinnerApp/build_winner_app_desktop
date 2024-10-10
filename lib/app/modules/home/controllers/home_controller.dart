import 'dart:async';

import 'package:build_winner_app_desktop/app/common/app_storage.dart';
import 'package:build_winner_app_desktop/app/routes/app_pages.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

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
  String get port => AppStorage.port.read() ?? '';

  /// 当前是否展开[构建项目列表]
  final isExpandBuildList = false.obs;

  /// 是否展开[等待队列]
  final isExpandQueueList = false.obs;

  /// 当前正在构建项目名称列表
  final buildNameList = <String>[].obs;

  /// 当前队列的任务列表
  final queueList = <QueueData>[].obs;

  Timer? _timer;

  @override
  onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    platformController = TabController(length: 2, vsync: this);

    init();

    /// 启动定时定时刷新
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await init(false);
    });
  }

  @override
  onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 初始化当前任务状态
  Future<void> init([bool showLoadiong = true]) async {
    if (showLoadiong) SmartDialog.showLoading();
    await _loadData();
    if (showLoadiong) SmartDialog.dismiss();
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
  }

  /// 检测当前是否还有进行中的任务

  /// 退出登录
  Future<void> logout() async {
    Get.offNamed(Routes.LOGIN);
  }

  /// 执行打包
  Future<void> build(BuildContext context) async {
    /// 是否存在正在运行的任务
    final isExitRuning = queueList.isNotEmpty || buildNameList.isNotEmpty;
    if (isExitRuning) {
      final result = await SmartDialog.show<bool>(builder: (context) {
        return TDAlertDialog(
          title: '当前存在正在运行的任务，是否继续打包？',
          buttonStyle: TDDialogButtonStyle.text,
          leftBtnAction: () => SmartDialog.dismiss(),
          rightBtnAction: () => SmartDialog.dismiss(result: true),
        );
      });
      if (!JSON(result).boolValue) {
        return;
      }
    }

    var channelKey = '73e3b5d240896856fbbdc8a0c1c551c3';
    var androidChannel = 'Winner';
    var forceBuild = false;
    var unityBranch = 'release2.0';
    var upload = true;
    var sendLog = true;
    var skipUnity = false;
    var buildNumber = DateTime.now().millisecondsSinceEpoch;
    var branch = flutterBranchController.text;
    if (isRelease.value) {
      channelKey = '';
      forceBuild = true;
      upload = false;
      sendLog = false;
      branch = 'release2.0';

      /// 合并代码到release2.0
      await buildWithParameters('merge_release', {
        'BRANCH': flutterBranchController.text,
      });
    }
    if (platformController.index == 0) {
      await _buildApp(
        channelKey: channelKey,
        androidChannel: androidChannel,
        forceBuild: forceBuild,
        unityBranch: unityBranch,
        upload: upload,
        sendLog: sendLog,
        skipUnity: skipUnity,
        buildNumber: buildNumber,
        flutterBranch: branch,
      );
    } else {
      Future<void> buildAndroid(String channel, bool skipUnity) async {
        await _buildApp(
          channelKey: channelKey,
          androidChannel: channel,
          forceBuild: forceBuild,
          unityBranch: unityBranch,
          upload: upload,
          sendLog: sendLog,
          skipUnity: skipUnity,
          buildNumber: buildNumber,
          flutterBranch: branch,
        );
      }

      await buildAndroid('Winner', false);

      if (isRelease.value) {
        final channels = [
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
          await buildAndroid(channels[i], true);
        }
      }
    }
  }

  Future<void> _buildApp({
    required String channelKey,
    required String androidChannel,
    required bool forceBuild,
    required String unityBranch,
    required bool upload,
    required bool sendLog,
    required bool skipUnity,
    required int buildNumber,
    required String flutterBranch,
  }) async {
    final platfrom = platformController.index == 0 ? 'ios' : 'android';
    final buildName = AppStorage.version.read() ?? '1.0.0';
    final data = {
      'BRANCH': 'origin/$flutterBranch',
      'PLATFROM': platfrom,
      'BUILD_NAME': buildName,
      'IS_STORE': isRelease.value ? 'true' : 'false',
      'ENVIRONMENT': '',
      'ZEALOT_CHANNEL_KEY': channelKey,
      'androidChannel': androidChannel,
      'FORCE_BUILD': forceBuild ? 'true' : 'false',
      'UNITY_BRANCH_NAME': unityBranch,
      'UPLOAD': upload ? 'true' : 'false',
      'SEND_LOG': sendLog ? 'true' : 'false',
      'SKIP_UNITY_UPDATE': skipUnity ? 'true' : 'false',
      'BUILD_NUMBER': buildNumber.toString(),
      'FLUTTER_LAST_COMMIT_HASH': '',
      'UNITY_LAST_COMMIT_HASH': '',
    };
    await buildWithParameters('meta_winner_app2', data);
  }

  Future<void> buildWithParameters(
      String jobName, Map<String, dynamic> data) async {
    final url = await getBuildWithParametersUrl(jobName);
    try {
      await Dio().post(url, queryParameters: data);
    } catch (e) {}
  }

  Future<String> getBuildWithParametersUrl(String jobName) async {
    final username = GetStorage().read('username');
    final password = GetStorage().read('password');
    String host = AppStorage.host.read() ?? '';
    String port = AppStorage.port.read() ?? '';
    return 'http://$username:$password@$host:$port/job/$jobName/buildWithParameters';
  }

  /// 获取最新的任务ID
  Future<String?> getLatestBuildId(String jobName) async {
    final url = 'http://$host:$port/job/$jobName/lastBuild/buildNumber';
    try {
      final response = await Dio().get(url);
      return response.data;
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
      return null;
    }
  }

  /// 获取当前任务详情
  Future<String?> getBuildDetail(String jobName, String buildId) async {
    final url = 'http://$host:$port/job/$jobName/$buildId/api/json?pretty=true';
    try {
      final response = await Dio().get(url);
      return response.data;
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
      return null;
    }
  }

  /// 查询当前队列任务状态
  Future<dynamic> getQueue() async {
    final url = 'http://$host:$port/queue/api/json';
    try {
      final response = await Dio().get(url);
      return response.data;
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
      return null;
    }
  }

  /// 查询当前Jenkins项目状态
  Future<dynamic> getProjects() async {
    final url = 'http://$host:$port/api/json';
    try {
      final response = await Dio().get(url);
      return response.data;
    } catch (e) {
      SmartDialog.showNotify(msg: e.toString(), notifyType: NotifyType.error);
      return null;
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
