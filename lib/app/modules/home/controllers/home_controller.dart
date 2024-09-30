import 'package:build_winner_app_desktop/app/common/app_storage.dart';
import 'package:build_winner_app_desktop/app/routes/app_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  @override
  onInit() {
    super.onInit();

    tabController = TabController(length: 2, vsync: this);

    platformController = TabController(length: 2, vsync: this);
  }

  /// 退出登录
  Future<void> logout() async {
    Get.offNamed(Routes.LOGIN);
  }

  /// 执行打包
  Future<void> build() async {
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
    print('$url $data');
    try {
      await Dio().post(url, queryParameters: data);
    } catch (e) {
      print(e);
    }
  }

  Future<String> getBuildWithParametersUrl(String jobName) async {
    final username = GetStorage().read('username');
    final password = GetStorage().read('password');
    String host = AppStorage.host.read() ?? '';
    String port = AppStorage.port.read() ?? '';
    return 'http://$username:$password@$host:$port/job/$jobName/buildWithParameters';
  }
}
