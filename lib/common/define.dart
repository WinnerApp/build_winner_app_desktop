import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:logger/web.dart';

final logger = Logger();
final dio = Dio()
  ..options.connectTimeout = 2.minutes
  ..options.receiveTimeout = 2.minutes
  ..options.sendTimeout = 2.minutes;
