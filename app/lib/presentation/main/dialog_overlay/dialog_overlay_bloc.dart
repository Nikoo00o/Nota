import 'package:app/core/enums/dialog_status.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_event.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';

class DialogOverlayBloc extends Bloc<DialogOverlayEvent, DialogOverlayState> {
  DialogStatus dialogStatus = DialogStatus.HIDDEN;
  String dialogTextKey = "";
  List<String>? dialogTextKeyParams;
  void Function()? navigationCallback;

  DialogOverlayBloc() : super(DialogOverlayState()) {
    registerEventHandlers();
  }

  void registerEventHandlers() {
    on<HideDialog>(_handleHideDialog);
    on<ShowLoadingDialog>(_handleShowLoadingDialog);
    on<ShowErrorDialog>(_handleShowErrorDialog);
    on<ShowConfirmDialog>(_handleShowConfirmDialog);
  }

  Future<void> _handleHideDialog(HideDialog event, Emitter<DialogOverlayState> emit) async {
    Logger.verbose("hiding dialog");
    dialogStatus = DialogStatus.HIDDEN;
    dialogTextKeyParams = null;
    navigationCallback = null;
    emit(_createState());
  }

  Future<void> _handleShowLoadingDialog(ShowLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    Logger.verbose("showing loading dialog");
    dialogStatus = DialogStatus.LOADING;
    dialogTextKey = event.dialogTextKey ?? "";
    dialogTextKeyParams = event.dialogTextKeyParams;
    navigationCallback = null;
    emit(_createState());
  }

  Future<void> _handleShowErrorDialog(ShowErrorDialog event, Emitter<DialogOverlayState> emit) async {
    Logger.verbose("showing error dialog");
    dialogStatus = DialogStatus.ERROR;
    dialogTextKey = event.dialogTextKey;
    dialogTextKeyParams = event.dialogTextKeyParams;
    navigationCallback = null;
    emit(_createState());
  }

  Future<void> _handleShowConfirmDialog(ShowConfirmDialog event, Emitter<DialogOverlayState> emit) async {
    Logger.verbose("showing confirm dialog");
    dialogStatus = DialogStatus.CONFIRM;
    dialogTextKey = event.dialogTextKey;
    dialogTextKeyParams = event.dialogTextKeyParams;
    navigationCallback = event.navigationCallback;
    emit(_createState());
  }

  DialogOverlayState _createState() {
    return DialogOverlayState(
      dialogStatus: dialogStatus,
      dialogTextKey: dialogTextKey,
      dialogTextKeyParams: dialogTextKeyParams,
      navigationCallback: navigationCallback,
    );
  }
}
