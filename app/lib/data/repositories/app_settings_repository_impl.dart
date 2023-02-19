import 'dart:ui';

import 'package:app/core/config/app_config.dart';
import 'package:app/data/datasources/local_data_source.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl extends AppSettingsRepository {

    final LocalDataSource localDataSource;
    final AppConfig appConfig;

    const AppSettingsRepositoryImpl({required this.localDataSource, required this.appConfig});

    @override
    Future<Locale> getCurrentLocale() async {
        return await localDataSource.getLocale() ?? appConfig.defaultLocale;
    }

    @override
    Future<void> setLocale(Locale locale) async {
        await localDataSource.setLocale(locale);
    }
}
