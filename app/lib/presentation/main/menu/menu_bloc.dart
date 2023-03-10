import 'package:app/domain/usecases/account/change/logout_of_account.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuBloc extends PageBloc<MenuEvent, MenuState> {
  final LogoutOfAccount logoutOfAccount;

  MenuBloc({required this.logoutOfAccount}) : super(initialState: const MenuState());

  @override
  void registerEventHandlers() {
    on<MenuEventInitialise>(_handleInitialise);
  }

  Future<void> _handleInitialise(MenuEventInitialise event, Emitter<MenuState> emit) async {
    emit(_buildState());
  }

  MenuState _buildState() {
    return const MenuState();
  }
}
