import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(AppLogger());
  await initializeGetIt();
  await Hive.initFlutter();

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Text("Test"),
      ),
    ),
  );
}
