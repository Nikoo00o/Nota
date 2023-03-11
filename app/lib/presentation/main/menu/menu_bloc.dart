import 'package:app/domain/usecases/account/get_user_name.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/page_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/usecases/usecase.dart';

class MenuBloc extends PageBloc<MenuEvent, MenuState> {
  final GetUsername getUsername;
  late String? userName;

  MenuBloc({
    required this.getUsername,
  }) : super(initialState: const MenuState());

  @override
  void registerEventHandlers() {
    on<MenuEventInitialise>(_handleInitialise);
  }

  Future<void> _handleInitialise(MenuEventInitialise event, Emitter<MenuState> emit) async {
    userName = await getUsername(const NoParams());
    emit(_buildState());
  }

  MenuState _buildState() {
    return MenuStateInitialized(userName: userName);
  }
}
