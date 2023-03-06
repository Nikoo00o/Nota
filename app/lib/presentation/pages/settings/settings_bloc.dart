import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/pages/settings/settings_event.dart';
import 'package:app/presentation/pages/settings/settings_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends PageBloc<SettingsEvent, SettingsState> {
  final LogoutOfAccount logoutOfAccount;

  SettingsBloc({required this.logoutOfAccount}) : super(initialState: const SettingsState());

  @override
  void registerEventHandlers() {
    on<SettingsEventInitialise>(_handleInitialise);
    on<SettingsEventLogout>(_handleLogout);
  }

  Future<void> _handleInitialise(SettingsEventInitialise event, Emitter<SettingsState> emit) async {
    emit(_buildState());
  }

  Future<void> _handleLogout(SettingsEventLogout event, Emitter<SettingsState> emit) async {
    await logoutOfAccount.call(const LogoutOfAccountParams(navigateToLoginPage: true));
  }

  SettingsState _buildState() {
    return const SettingsState();
  }
}
