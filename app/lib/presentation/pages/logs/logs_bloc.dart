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

class LogsBloc extends PageBloc<LogsEvent, LogsState> {
  final AppSettingsRepository appSettingsRepository;
  final NavigationService navigationService;
  final DialogService dialogService;

  final ScrollController scrollController = ScrollController();

  late int logLevelIndex;

  LogLevel? filterLevel;

  LogsBloc({
    required this.appSettingsRepository,
    required this.navigationService,
    required this.dialogService,
  }) : super(initialState: const LogsState());

  @override
  void registerEventHandlers() {
    on<LogsEventInitialise>(_handleInitialise);
    on<LogsEventChangeLogLevel>(_handleChangeLogLevel);
    on<LogsEventFilterLogLevel>(_handleFilterLogLevel);
  }

  Future<void> _handleInitialise(LogsEventInitialise event, Emitter<LogsState> emit) async {
    filterLevel = await appSettingsRepository.getLogLevel();
    logLevelIndex = filterLevel!.index;
    emit(await _buildState());
  }

  Future<void> _handleChangeLogLevel(LogsEventChangeLogLevel event, Emitter<LogsState> emit) async {
    logLevelIndex = event.newLogLevelIndex;
    await appSettingsRepository.setLogLevel(LogLevel.values.elementAt(logLevelIndex));
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
    );
  }
}
