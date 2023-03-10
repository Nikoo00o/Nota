import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:flutter/material.dart';

/// There are many dialog options, but you can always show a fully custom dialog with [showCustomDialog]!
///
/// This class only provides access to the dialog overlay bloc and can be mocked for tests!
///
/// For Documentation on how to use the dialogs, look at [DialogOverlayBloc].
abstract class DialogService {
  const DialogService();

  /// This can be used to add any of the different dialog types which inherit from [DialogOverlayEvent].
  void show(DialogOverlayEvent params);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowLoadingDialog].
  void showLoadingDialog([ShowLoadingDialog? params]);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowCustomDialog].
  void showCustomDialog(ShowCustomDialog params);

  /// Shows a small info [SnackBar] at the bottom of the screen. this should only be used for small status updates.
  /// For bigger more relevant info, use [ShowInfoDialog].
  ///
  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowInfoSnackBar].
  void showInfoSnackBar(ShowInfoSnackBar params);

  /// Shows an information dialog with a title, text and a confirm button. If the information is meaningless and small,
  /// consider using [ShowInfoSnackBar] instead!
  ///
  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowInfoDialog].
  void showInfoDialog(ShowInfoDialog params);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowErrorDialog].
  void showErrorDialog(ShowErrorDialog params);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowConfirmDialog].
  void showConfirmDialog(ShowConfirmDialog params);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowInputDialog].
  void showInputDialog(ShowInputDialog params);

  /// Shows the specified dialog with many optional parameter. For the [params], look at [ShowSelectDialog].
  void showSelectionDialog(ShowSelectDialog params);

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
  void show(DialogOverlayEvent params){
    dialogOverlayBloc.add(params);
  }

  @override
  void showLoadingDialog([ShowLoadingDialog? params]) {
    dialogOverlayBloc.add(params ?? const ShowLoadingDialog());
  }

  @override
  void showCustomDialog(ShowCustomDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showInfoSnackBar(ShowInfoSnackBar params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showInfoDialog(ShowInfoDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showErrorDialog(ShowErrorDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showConfirmDialog(ShowConfirmDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showInputDialog(ShowInputDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void showSelectionDialog(ShowSelectDialog params) {
    dialogOverlayBloc.add(params);
  }

  @override
  void hideDialog() {
    dialogOverlayBloc.add(const HideDialog(cancelDialog: true));
  }

  @override
  void hideLoadingDialog() {
    dialogOverlayBloc.add(const HideLoadingDialog());
  }

  @override
  bool get isDialogVisible => dialogOverlayBloc.isCustomDialogVisible;

  @override
  bool get isLoading => dialogOverlayBloc.isLoadingDialogVisible;
}
