import 'package:app/core/get_it.dart';
import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main(List<String> arguments) async {
  FlutterCryptography.enable(); // enable flutter cryptography for better performance
  DArgon2Flutter.init(); // enable flutter argon2 for better performance
  await initializeGetIt();
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
