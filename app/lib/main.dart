import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  FlutterCryptography.enable(); // enable flutter cryptography for better performance
  await initializeGetIt();
  Logger.initLogger(AppLogger());
  await sl<LocalDataSource>().init();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Text("Test"),
      ),
    ),
  );
}
