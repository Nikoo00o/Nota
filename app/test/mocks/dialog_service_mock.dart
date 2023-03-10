import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';

class DialogServiceMock extends DialogService {
  /// Used to mock the [showConfirmDialog] response if the user confirms the dialog, or not
  bool confirmedOverride = true;

  @override
  void show(DialogOverlayEvent params) {}

  @override
  void showLoadingDialog([ShowLoadingDialog? params]) {}

  @override
  void showCustomDialog(ShowCustomDialog params) {}

  @override
  void showInfoSnackBar(ShowInfoSnackBar params) {}

  @override
  void showInfoDialog(ShowInfoDialog params) {}

  @override
  void showErrorDialog(ShowErrorDialog params) {}

  @override
  void showConfirmDialog(ShowConfirmDialog params) {}

  @override
  void showInputDialog(ShowInputDialog params) {}

  @override
  void showSelectionDialog(ShowSelectDialog params) {}

  @override
  void hideDialog() {}

  @override
  void hideLoadingDialog() {}

  @override
  bool get isDialogVisible => false;

  @override
  bool get isLoading => false;
}
