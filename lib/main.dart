import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';

Future<void> main() async {
  await GetStorage.init();

  String initialRoute = Routes.LOGIN;
  // if (GetStorage().read('username') != null) {
  //   initialRoute = Routes.HOME;
  // }

  runApp(
    GetMaterialApp(
      title: "Application",
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(),
    ),
  );

  FlutterError.onError = (e) {
    SmartDialog.showToast(e.toString(), displayTime: 3.seconds);
  };
}
