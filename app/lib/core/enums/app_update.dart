import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/main/app/app_bloc.dart';

/// used to update the [AppBloc] from the [AppSettingsRepository]
enum AppUpdate {
  LOCALE,
  DARK_THEME;
}
