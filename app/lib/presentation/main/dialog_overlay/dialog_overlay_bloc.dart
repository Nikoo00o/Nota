import 'package:app/presentation/main/dialog_overlay/dialog_overlay_event.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/utils/logger/logger.dart';

class DialogOverlayBloc extends Bloc<DialogOverlayEvent, DialogOverlayState> {
  /// The global dialog key to access the BuildContext to modify the dialogs!
  final GlobalKey dialogOverlayKey;

  final TranslationService translationService;

  bool isLoadingDialogVisible = false;
  bool isCustomDialogVisible = false;

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
  }

  Future<void> _handleHideDialog(HideDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(isLoadingDialog: false, dataForDialog: event.dataForDialog);
  }

  Future<void> _handleHideLoadingDialog(HideLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(isLoadingDialog: true);
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
    await _showDialog(
      titleKey: event.titleKey!,
      titleKeyParams: event.titleKeyParams,
      titleStyle: event.titleStyle,
      titleIcon: event.titleIcon,
      content: event.content,
      actions: event.buttons,
    );
  }

  Future<void> _handleShowInfoSnackBar(ShowInfoSnackBar event, Emitter<DialogOverlayState> emit) async {
    ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
      content: Text(_translate(event.textKey, keyParams: event.textKeyParams), style: event.textStyle),
    ));
  }

  Future<void> _handleShowInfoDialog(ShowInfoDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.confirm.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: event.titleStyle,
      titleIcon: event.titleIcon,
      content: Text(
        _translate(event.descriptionKey, keyParams: event.titleKeyParams),
        style: event.descriptionStyle,
      ),
      actions: <Widget>[
        TextButton(
          style: event.confirmButtonStyle,
          onPressed: () {
            _closeDialog();
            event.onConfirm?.call();
          },
          child: Text(_translate(event.confirmButtonKey ?? "dialog.confirm.ok", keyParams: event.confirmButtonKeyParams)),
        ),
      ],
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
    if (isLoadingDialog) {
      if (isLoadingDialogVisible) {
        Logger.verbose("a loading dialog is already open");
        return null;
      }
      Logger.verbose("showing loading dialog $titleKey with $titleKeyParams");
      isLoadingDialogVisible = true;
    } else {
      if (isCustomDialogVisible) {
        Logger.error("a custom dialog is already open");
        return null;
      }
      Logger.verbose("showing custom $titleKey with $titleKeyParams");
      isCustomDialogVisible = true;
    }
    return showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: titleIcon,
          title: Text(_translate(titleKey, keyParams: titleKeyParams)),
          titleTextStyle: titleStyle,
          content: SingleChildScrollView(
            child: content,
          ),
          actions: actions,
        );
      },
    );
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
  void _closeDialog({Object? dataForDialog, bool isLoadingDialog = false}) {
    if (isLoadingDialog == false) {
      if (isCustomDialogVisible) {
        Logger.verbose("closing custom dialog with $dataForDialog");
        Navigator.of(_context).pop(dataForDialog);
        isCustomDialogVisible = false;
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

  String _translate(String key, {List<String>? keyParams}) {
    return translationService.translate(key, keyParams: keyParams);
  }

  BuildContext get _context => dialogOverlayKey.currentContext!;

  ColorScheme get _colors => Theme.of(_context).colorScheme;
}
