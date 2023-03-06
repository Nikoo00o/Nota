import 'package:app/core/enums/dialog_status.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_event.dart';

abstract class DialogService {
  const DialogService();

  /// Non blocking
  void showErrorDialog(String dialogTextKey, {List<String>? dialogTextKeyParams});

  /// Non blocking
  void showInfoDialog(String dialogTextKey, {List<String>? dialogTextKeyParams});

  /// Non blocking
  void showLoadingDialog({String? dialogTextKey, List<String>? dialogTextKeyParams});

  /// Shows a dialog with the [dialogTextKey] as description text if not null and otherwise a default "Confirm" message.
  /// If [cancelTextKey] is null, then the dialog will only have one button.
  ///
  /// Returns [true] if the [confirmTextKey] button was pressed and false if the [cancelTextKey] button was pressed.
  /// Blocks the calling function until the user pressed a button.
  Future<bool> showConfirmDialog({
    String? dialogTextKey,
    List<String>? dialogTextKeyParams,
    required String confirmTextKey,
    List<String>? confirmTextKeyParams,
    String? cancelTextKey,
    List<String>? cancelTextKeyParams,
  });

  /// Hides the last dialog
  void hideDialog();

  /// Only hides loading dialog
  void hideLoadingDialog();

  /// returns if a dialog is visible
  bool get isDialogVisible;

  /// returns if a loading dialog is visible
  bool get isLoading;
}

class DialogServiceImpl extends DialogService {
  final DialogOverlayBloc dialogOverlayBloc;

  const DialogServiceImpl({required this.dialogOverlayBloc});

  @override
  void showErrorDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {
    dialogOverlayBloc.add(ShowErrorDialog(dialogTextKey, dialogTextKeyParams));
  }

  @override
  void showInfoDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {
    dialogOverlayBloc.add(ShowErrorDialog(dialogTextKey, dialogTextKeyParams)); //todo: add in dialog service + bloc
  }

  @override
  void showLoadingDialog({String? dialogTextKey, List<String>? dialogTextKeyParams}) {
    dialogOverlayBloc.add(ShowLoadingDialog(dialogTextKey, dialogTextKeyParams));
  }

  @override
  Future<bool> showConfirmDialog({
    String? dialogTextKey,
    List<String>? dialogTextKeyParams,
    required String confirmTextKey,
    List<String>? confirmTextKeyParams,
    String? cancelTextKey,
    List<String>? cancelTextKeyParams,
  }) async {
    dialogOverlayBloc.add(ShowConfirmDialog(dialogTextKey ?? "dialog.confirm", dialogTextKeyParams, () {}));
    // todo: change event, also prevent back navigation for all dialogs! this service is not fully implemented yet!!!!!
    return true;
  }

  @override
  void hideDialog() {
    dialogOverlayBloc.add(const HideDialog());
  }

  @override
  void hideLoadingDialog() {
    dialogOverlayBloc.add(const HideDialog());
    //todo: add dialog counter for loading dialog, etc
  }

  @override
  bool get isDialogVisible => dialogOverlayBloc.dialogStatus != DialogStatus.HIDDEN;

  @override
  bool get isLoading => dialogOverlayBloc.dialogStatus == DialogStatus.LOADING;
}
