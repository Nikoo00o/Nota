import 'package:app/core/config/app_config.dart';
import 'package:app/core/get_it.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/presentation/pages/logs/logs_event.dart';
import 'package:app/presentation/pages/logs/logs_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/enums/log_level.dart';
import 'package:shared/core/utils/logger/log_message.dart';
import 'package:shared/core/utils/logger/logger.dart';

final class LogsBloc extends PageBloc<LogsEvent, LogsState> {
  final AppSettingsRepository appSettingsRepository;
  final NavigationService navigationService;
  final DialogService dialogService;
  final AppConfig appConfig;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  late int logLevelIndex;

  LogLevel? filterLevel;

  LogsBloc({
    required this.appSettingsRepository,
    required this.navigationService,
    required this.dialogService,
    required this.appConfig,
  }) : super(initialState: const LogsState());

  @override
  void registerEventHandlers() {
    on<LogsEventInitialise>(_handleInitialise);
    on<LogsEventUpdateState>(_handleUpdateState);
    on<LogsEventChangeLogLevel>(_handleChangeLogLevel);
    on<LogsEventFilterLogLevel>(_handleFilterLogLevel);
  }

  Future<void> _handleInitialise(LogsEventInitialise event, Emitter<LogsState> emit) async {
    dialogService.showLoadingDialog();
    await appSettingsRepository.getLogs(); // load logs into memory once while showing loading dialog
    filterLevel = await appSettingsRepository.getLogLevel();
    logLevelIndex = filterLevel!.index;
    emit(await _buildState());
    dialogService.hideLoadingDialog();
  }

  Future<void> _handleUpdateState(LogsEventUpdateState event, Emitter<LogsState> emit) async {
    emit(await _buildState());
  }

  Future<void> _handleChangeLogLevel(LogsEventChangeLogLevel event, Emitter<LogsState> emit) async {
    logLevelIndex = event.newLogLevelIndex;
    final LogLevel newLogLevel = LogLevel.values.elementAt(logLevelIndex);
    final LogLevel oldLogLevel = await appSettingsRepository.getLogLevel();
    if (oldLogLevel != newLogLevel) {
      await appSettingsRepository.setLogLevel(newLogLevel);
      Logger.initLogger(AppLogger(logLevel: newLogLevel, appConfig: sl(), appSettingsRepository: sl()));
    }
    emit(await _buildState());
  }

  Future<void> _handleFilterLogLevel(LogsEventFilterLogLevel event, Emitter<LogsState> emit) async {
    filterLevel = event.logLevel;
    emit(await _buildState());
  }

  Future<LogsState> _buildState() async {
    final List<LogMessage> messages = await appSettingsRepository.getLogs();
    final LogLevel filter = filterLevel ?? await appSettingsRepository.getLogLevel();

    return LogsStateInitialised(
      logMessages: messages.where((LogMessage message) => message.canLog(filter)).toList(),
      filterLevel: filter,
      currentLogLevelIndex: logLevelIndex,
      searchText: appConfig.searchCaseSensitive ? searchController.text : searchController.text.toLowerCase(),
    );
  }
}
