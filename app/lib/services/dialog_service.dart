import 'dart:async';

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

  /// Shows the about dialog with the license, etc
  void showAboutDialog();

  /// Hides the last dialog
  void hideDialog();

  /// Only hides loading dialog
  void hideLoadingDialog();

  /// This is used inside of the [DialogOverlayBloc] to listen for events that this service adds.
  /// For testing this just returns null!
  StreamSubscription<DialogOverlayEvent>? listen(void Function(DialogOverlayEvent) callback);
}

class DialogServiceImpl extends DialogService {
  /// stream controller to add the update events
  final StreamController<DialogOverlayEvent> _updateController = StreamController<DialogOverlayEvent>();

  /// broadcast stream that is used to listen for update events for the [DialogOverlayBloc]
  late final Stream<DialogOverlayEvent> _updateStream;

  DialogServiceImpl() {
    _updateStream = _updateController.stream.asBroadcastStream();
  }

  @override
  void show(DialogOverlayEvent params) {
    _updateController.add(params);
  }

  @override
  void showLoadingDialog([ShowLoadingDialog? params]) {
    _updateController.add(params ?? const ShowLoadingDialog());
  }

  @override
  void showCustomDialog(ShowCustomDialog params) {
    _updateController.add(params);
  }

  @override
  void showInfoSnackBar(ShowInfoSnackBar params) {
    _updateController.add(params);
  }

  @override
  void showInfoDialog(ShowInfoDialog params) {
    _updateController.add(params);
  }

  @override
  void showErrorDialog(ShowErrorDialog params) {
    _updateController.add(params);
  }

  @override
  void showConfirmDialog(ShowConfirmDialog params) {
    _updateController.add(params);
  }

  @override
  void showInputDialog(ShowInputDialog params) {
    _updateController.add(params);
  }

  @override
  void showSelectionDialog(ShowSelectDialog params) {
    _updateController.add(params);
  }

  @override
  void showAboutDialog() {
    _updateController.add(const ShowAboutDialog());
  }

  @override
  void hideDialog() {
    _updateController.add(const HideDialog(cancelDialog: true));
  }

  @override
  void hideLoadingDialog() {
    _updateController.add(const HideLoadingDialog());
  }

  @override
  StreamSubscription<DialogOverlayEvent>? listen(void Function(DialogOverlayEvent) callback) =>
      _updateStream.listen(callback);
}
