import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';

/// For now the mock provides empty data for the confirm dialogs that need data
class DialogServiceMock extends DialogService {
  /// Used to mock the [showConfirmDialog] response if the user confirms the dialog, or not
  bool confirmedOverride = true;

  @override
  void show(DialogOverlayEvent params) {
    if (params is ShowInfoDialog) {
      params.onConfirm?.call();
    } else if (params is ShowErrorDialog) {
      params.onConfirm?.call();
    } else if (params is ShowConfirmDialog) {
      if (confirmedOverride) {
        params.onConfirm?.call();
      } else {
        params.onCancel?.call();
      }
    } else if (params is ShowInputDialog) {
      if (confirmedOverride) {
        params.onConfirm.call("");
      } else {
        params.onCancel?.call();
      }
    } else if (params is ShowSelectDialog) {
      if (confirmedOverride) {
        params.onConfirm.call(0);
      } else {
        params.onCancel?.call();
      }
    }
  }

  @override
  void showLoadingDialog([ShowLoadingDialog? params]) {}

  @override
  void showCustomDialog(ShowCustomDialog params) {}

  @override
  void showInfoSnackBar(ShowInfoSnackBar params) {}

  @override
  void showInfoDialog(ShowInfoDialog params) {
    params.onConfirm?.call();
  }

  @override
  void showErrorDialog(ShowErrorDialog params) {
    params.onConfirm?.call();
  }

  @override
  void showConfirmDialog(ShowConfirmDialog params) {
    if (confirmedOverride) {
      params.onConfirm?.call();
    } else {
      params.onCancel?.call();
    }
  }

  @override
  void showInputDialog(ShowInputDialog params) {
    if (confirmedOverride) {
      params.onConfirm.call("");
    } else {
      params.onCancel?.call();
    }
  }

  @override
  void showSelectionDialog(ShowSelectDialog params) {
    if (confirmedOverride) {
      params.onConfirm.call(0);
    } else {
      params.onCancel?.call();
    }
  }

  @override
  void hideDialog() {}

  @override
  void hideLoadingDialog() {}

  @override
  bool get isDialogVisible => false;

  @override
  bool get isLoading => false;
}
