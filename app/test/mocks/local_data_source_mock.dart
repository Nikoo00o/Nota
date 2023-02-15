import 'package:app/data/datasources/local_data_source.dart';

class LocalDataSourceImpl extends LocalDataSource {
  Map<String, String> hiveStorage = <String, String>{};
  Map<String, String> secureStorage = <String, String>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> write({required String key, required String? value, required bool secure}) async {
    if (value == null) {
      return delete(key: key, secure: secure);
    }
    if (secure == false) {
      hiveStorage[key] = value;
    } else {
      secureStorage[key] = value;
    }
  }

  @override
  Future<String?> read({required String key, required bool secure}) async {
    if (secure == false) {
      return hiveStorage[key];
    } else {
      return secureStorage[key];
    }
  }

  @override
  Future<void> delete({required String key, required bool secure}) async {
    if (secure == false) {
      hiveStorage.remove(key);
    } else {
      secureStorage.remove(key);
    }
  }
}
