import 'package:get_storage/get_storage.dart';

enum AppStorage {
  host('host'),
  port('port'),
  username('username'),
  password('password'),
  version('version');

  final String key;
  const AppStorage(this.key);

  T? read<T>() {
    return GetStorage().read(key);
  }

  Future<void> write<T>(T value) async {
    return GetStorage().write(key, value);
  }
}
