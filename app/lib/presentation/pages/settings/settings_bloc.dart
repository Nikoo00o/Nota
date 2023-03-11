import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends PageBloc<SettingsEvent, SettingsState> {

  SettingsBloc() : super(initialState: const SettingsState());

  @override
  void registerEventHandlers() {
    on<SettingsEventInitialise>(_handleInitialise);
  }

  Future<void> _handleInitialise(SettingsEventInitialise event, Emitter<SettingsState> emit) async {
    emit(_buildState());
  }

  SettingsState _buildState() {
    return const SettingsState();
  }
}
