import 'dart:async';

import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';

part "dialog_overlay_event.dart";

/// All dialogs only need translation keys, because they will be automatically translated!
///
/// In general there is only ever one dialog visible at once and loading dialogs will be closed in favor for other dialogs!
///
/// Dialogs may not create other dialogs themselves!
class DialogOverlayBloc extends Bloc<DialogOverlayEvent, DialogOverlayState> {
  /// The global dialog key to access the BuildContext to modify the dialogs!
  final GlobalKey dialogOverlayKey;

  final TranslationService translationService;

  bool isLoadingDialogVisible = false;
  bool isCustomDialogVisible = false;

  /// This is also updated the same as [isLoadingDialogVisible] and [isCustomDialogVisible] and it will be used when the
  /// user presses the back button to cancel the current dialog!
  ///
  /// This only counts for the confirm, input and selection dialogs.
  VoidCallback? _cancelCallback;

  DialogOverlayBloc({
    required this.dialogOverlayKey,
    required this.translationService,
  }) : super(DialogOverlayState(dialogOverlayKey: dialogOverlayKey)) {
    registerEventHandlers();
  }

  void registerEventHandlers() {
    on<HideDialog>(_handleHideDialog);
    on<HideLoadingDialog>(_handleHideLoadingDialog);
    on<ShowLoadingDialog>(_handleShowLoadingDialog);
    on<ShowCustomDialog>(_handleShowCustomDialog);
    on<ShowInfoSnackBar>(_handleShowInfoSnackBar);
    on<ShowInfoDialog>(_handleShowInfoDialog);
    on<ShowErrorDialog>(_handleShowErrorDialog);
    on<ShowConfirmDialog>(_handleShowConfirmDialog);
    on<ShowInputDialog>(_handleShowInputDialog);
    on<ShowSelectDialog>(_handleShowSelectDialog);
  }

  Future<void> _handleHideDialog(HideDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(isLoadingDialog: false, dataForDialog: event.dataForDialog, cancelDialog: event.cancelDialog);
  }

  Future<void> _handleHideLoadingDialog(HideLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(isLoadingDialog: true, cancelDialog: false);
  }

  Future<void> _handleShowLoadingDialog(ShowLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.loading.title",
      titleKeyParams: event.titleKeyParams,
      isLoadingDialog: true,
      content: Column(
        children: <Widget>[
          const SizedBox(height: 20.0),
          SizedBox(
            height: 60.0,
            width: 60.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_colors.onBackground),
            ),
          ),
          const SizedBox(height: 30.0),
          Text(_translate(event.descriptionKey ?? "dialog.loading.description", keyParams: event.descriptionKeyParams)),
        ],
      ),
    );
  }

  Future<void> _handleShowCustomDialog(ShowCustomDialog event, Emitter<DialogOverlayState> emit) async {
    if (_isDialogAlreadyVisible(isLoadingDialog: false)) {
      return;
    }
    _cancelCallback = event.onBackPressed;
    return showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(onWillPop: () async => _onWillPop(context), child: event.builder(context));
      },
    );
  }

  Future<void> _handleShowInfoSnackBar(ShowInfoSnackBar event, Emitter<DialogOverlayState> emit) async {
    ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
      content: Text(_translate(event.textKey, keyParams: event.textKeyParams), style: event.textStyle),
      action: SnackBarAction(
        label: _translate("dialog.button.confirm"),
        onPressed: () {
          ScaffoldMessenger.of(_context).hideCurrentSnackBar();
        },
      ),
    ));
  }

  Future<void> _handleShowInfoDialog(ShowInfoDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.info.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: event.titleStyle,
      titleIcon: event.titleIcon,
      content: Text(
        _translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
        style: event.descriptionStyle,
      ),
      actions: <Widget>[
        _buildTextButton(
          textKey: event.confirmButtonKey ?? "dialog.button.confirm",
          textKeyParams: event.confirmButtonKeyParams,
          style: event.confirmButtonStyle,
          onClick: event.onConfirm,
        )
      ],
    );
  }

  Future<void> _handleShowErrorDialog(ShowErrorDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.error.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: TextStyle(color: _colors.error),
      titleIcon: event.titleIcon,
      content: Text(
        _translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
        style: event.descriptionStyle,
      ),
      actions: <Widget>[
        _buildTextButton(
          textKey: event.confirmButtonKey ?? "dialog.button.confirm",
          textKeyParams: event.confirmButtonKeyParams,
          style: event.confirmButtonStyle,
          onClick: event.onConfirm,
        )
      ],
    );
  }

  Future<void> _handleShowConfirmDialog(ShowConfirmDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.confirm.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: event.titleStyle,
      titleIcon: event.titleIcon,
      content: Text(
        _translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
        style: event.descriptionStyle,
      ),
      actions: <Widget>[
        _buildCancelButton(event),
        _buildTextButton(
          textKey: event.confirmButtonKey ?? "dialog.button.confirm",
          textKeyParams: event.confirmButtonKeyParams,
          style: event.confirmButtonStyle,
          onClick: event.onConfirm,
        ),
      ],
    );
  }

  Future<void> _handleShowInputDialog(ShowInputDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.confirm.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: event.titleStyle,
      titleIcon: event.titleIcon,
      content: Text(
        _translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
        style: event.descriptionStyle,
      ),
      actions: <Widget>[
        _buildCancelButton(event),
        _buildTextButton(
          textKey: event.confirmButtonKey ?? "dialog.button.confirm",
          textKeyParams: event.confirmButtonKeyParams,
          style: event.confirmButtonStyle,
          onClick: () {
            //todo: somehow connect state, see web
          },
        ),
      ],
    );
  }

  Future<void> _handleShowSelectDialog(ShowSelectDialog event, Emitter<DialogOverlayState> emit) async {}

  /// Builds a default text button that closes the dialog on a button press
  TextButton _buildTextButton({
    required String textKey,
    List<String>? textKeyParams,
    VoidCallback? onClick,
    ButtonStyle? style,
  }) {
    late final ButtonStyle textButtonStyle;
    if (style != null) {
      if (style.foregroundColor != null) {
        textButtonStyle = style.copyWith(foregroundColor: MaterialStatePropertyAll<Color>(_colors.tertiary));
      }
    } else {
      textButtonStyle = ButtonStyle(foregroundColor: MaterialStatePropertyAll<Color>(_colors.tertiary));
    }

    return TextButton(
      style: textButtonStyle,
      onPressed: () {
        _closeDialog(cancelDialog: false);
        onClick?.call();
      },
      child: Text(_translate(textKey, keyParams: textKeyParams)),
    );
  }

  /// Builds a default cancel button for the [event] for which the onCancel callback will also be called when the user
  /// navigates back!
  TextButton _buildCancelButton(_CancelDialog event) {
    _cancelCallback = event.onCancel;
    return _buildTextButton(
      textKey: event.cancelButtonKey ?? "dialog.button.cancel",
      textKeyParams: event.cancelButtonKeyParams,
      style: event.cancelButtonStyle,
      onClick: event.onCancel,
    );
  }

  /// Returns the result parameter data of the call to [_closeDialog] which closed the dialog.
  ///
  /// All [actions] must call [_closeDialog] to close the dialog!
  ///
  /// The alert dialog [content] will be wrapped inside of a [SingleChildScrollView].
  ///
  /// This will return [null] and not display the dialog if another dialog of the same kind is already visible!
  Future<Object?> _showDialog({
    required String titleKey,
    List<String>? titleKeyParams,
    TextStyle? titleStyle,
    Widget? titleIcon,
    required Widget content,
    List<Widget> actions = const <Widget>[],
    bool isLoadingDialog = false,
  }) async {
    if (_isDialogAlreadyVisible(isLoadingDialog: isLoadingDialog)) {
      return null;
    }
    return showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => _onWillPop(context),
          child: AlertDialog(
            icon: titleIcon,
            title: Text(_translate(titleKey, keyParams: titleKeyParams)),
            titleTextStyle: titleStyle,
            content: SingleChildScrollView(
              child: content,
            ),
            actions: actions,
          ),
        );
      },
    );
  }

  bool _isDialogAlreadyVisible({required bool isLoadingDialog}) {
    if (isLoadingDialog) {
      if (isLoadingDialogVisible || isCustomDialogVisible) {
        Logger.verbose("a loading, or base dialog is already open");
        return true;
      }
      Logger.verbose("showing loading dialog");
      isLoadingDialogVisible = true;
    } else {
      if (isCustomDialogVisible) {
        Logger.error("a base dialog is already open");
        return true;
      } else if (isLoadingDialogVisible) {
        Logger.verbose("closing error dialog in favor of base dialog");
        _closeDialog(cancelDialog: false, isLoadingDialog: true);
      }
      Logger.verbose("showing some base dialog");
      isCustomDialogVisible = true;
    }
    return false;
  }

  /// This closes the dialog with a call to "Navigator.of(context).pop()" and passed the [dataForDialog] which will be
  /// returned from [_showDialog].
  ///
  /// If [isLoadingDialog] is false, then both dialog types will be closed, otherwise only the loading dialog will be
  /// closed.
  ///
  /// A loading dialog will never receive the [dataForDialog]!
  ///
  /// Important: this will also be called with [dataForDialog] set to [null] when the user presses the back button except
  /// when the loading dialog is visible!
  ///
  /// If [cancelDialog] is true, then the custom onCancel callback of the dialog will be called as well.
  /// Otherwise it will not be called (for example internally after closing the dialog from the confirm button).
  void _closeDialog({Object? dataForDialog, bool isLoadingDialog = false, required bool cancelDialog}) {
    if (isLoadingDialog == false) {
      if (isCustomDialogVisible) {
        Logger.verbose("closing custom dialog with $dataForDialog");
        if (cancelDialog && _cancelCallback != null) {
          Logger.verbose("also calling the custom dialog cancel callback");
          _cancelCallback?.call();
        }
        Navigator.of(_context).pop(dataForDialog);
        isCustomDialogVisible = false;
        _cancelCallback = null;
      } else {
        Logger.warn("tried to close custom dialog with $dataForDialog, but none was visible");
      }
    }
    // if a loading dialog is also visible, then the context must be popped twice!
    if (isLoadingDialogVisible) {
      Logger.verbose("closing loading dialog");
      Navigator.of(_context).pop(dataForDialog);
      isLoadingDialogVisible = false;
    } else if (isLoadingDialog) {
      Logger.warn("tried to close loading dialog, but none was visible");
    }
  }

  /// Returns false if a custom back navigation was executed.
  /// Returns true if the app should navigate back (in most cases terminate the app).
  ///
  /// If a loading dialog is visible, then nothing will happen, but any other dialog will be cancelled!
  Future<bool> _onWillPop(BuildContext context) async {
    if (isLoadingDialogVisible) {
      return false;
    } else if (isCustomDialogVisible) {
      _closeDialog(isLoadingDialog: false, dataForDialog: null, cancelDialog: true);
      return false;
    }
    return true;
  }

  String _translate(String key, {List<String>? keyParams}) {
    return translationService.translate(key, keyParams: keyParams);
  }

  BuildContext get _context => dialogOverlayKey.currentContext!;

  ColorScheme get _colors => Theme.of(_context).colorScheme;
}
