import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

Future<void> main(List<String> arguments) async {
  Logger.initLogger(AppLogger());
  await initializeGetIt();
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Text("Test"),
      ),
    ),
  );
}
