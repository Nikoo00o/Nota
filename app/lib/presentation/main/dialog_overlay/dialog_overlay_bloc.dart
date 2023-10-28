import 'dart:async';

import 'package:app/core/constants/assets.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:app/presentation/main/dialog_overlay/widgets/input_dialog.dart';
import 'package:app/presentation/main/dialog_overlay/widgets/loading_dialog_content.dart';
import 'package:app/presentation/main/dialog_overlay/widgets/selection_dialog.dart';
import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final DialogService dialogService;

  /// 0 means that no loading dialog is visible
  int loadingDialogCounter = 0;
  bool isCustomDialogVisible = false;

  /// This is also updated the same as [loadingDialogCounter] and [isCustomDialogVisible] and it will be used when the
  /// user presses the back button to cancel the current dialog!
  ///
  /// This only counts for the confirm, input and selection dialogs.
  VoidCallback? _cancelCallback;

  /// gets the events from the [DialogService]
  late final StreamSubscription<DialogOverlayEvent>? streamSubscription;

  DialogOverlayBloc({
    required this.dialogOverlayKey,
    required this.translationService,
    required this.dialogService,
  }) : super(DialogOverlayState(dialogOverlayKey: dialogOverlayKey)) {
    registerEventHandlers();
    streamSubscription = dialogService.listen((DialogOverlayEvent event) async {
      // add event to emit a new state and rebuild depending on the change
      add(event);
    });
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
    on<ShowAboutDialog>(_handleShowAboutDialog);
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    return super.close();
  }

  Future<void> _handleHideDialog(HideDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(
      isLoadingDialog: false,
      dataForDialog: event.dataForDialog,
      cancelDialog: event.cancelDialog,
      forceCloseLoadingDialog: true,
    );
  }

  Future<void> _handleHideLoadingDialog(HideLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    _closeDialog(isLoadingDialog: true, cancelDialog: false);
  }

  Future<void> _handleShowLoadingDialog(ShowLoadingDialog event, Emitter<DialogOverlayState> emit) async {
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.loading.title",
      titleKeyParams: event.titleKeyParams,
      isLoadingDialog: true,
      content: LoadingDialogContent(
        descriptionKey: event.descriptionKey,
        descriptionKeyParams: event.descriptionKeyParams,
      ),
    );
  }

  Future<void> _handleShowCustomDialog(ShowCustomDialog event, Emitter<DialogOverlayState> emit) async {
    final Object? data = await _showDialogHelper(
        isLoadingDialog: false,
        newCancelCallback: event.onBackPressed,
        dialogBuilder: (BuildContext context) => event.builder(context));
    event.onData?.call(data);
  }

  Future<void> _handleShowInfoSnackBar(ShowInfoSnackBar event, Emitter<DialogOverlayState> emit) async {
    ScaffoldMessenger.of(context!).showSnackBar(SnackBar(
      duration: event.duration,
      content: Text(translate(event.textKey, keyParams: event.textKeyParams), style: event.textStyle),
      action: SnackBarAction(
        label: translate("dialog.button.confirm"),
        onPressed: () {
          ScaffoldMessenger.of(context!).hideCurrentSnackBar();
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
        translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
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
    if (context == null) {
      return;
    }
    await _showDialog(
      titleKey: event.titleKey ?? "dialog.error.title",
      titleKeyParams: event.titleKeyParams,
      titleStyle: Theme.of(context!).textTheme.titleLarge?.copyWith(color: colors.error),
      titleIcon: event.titleIcon,
      content: Text(
        translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
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
      newCancelCallback: event.onCancel,
      content: Text(
        translate(event.descriptionKey, keyParams: event.descriptionKeyParams),
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
    // the data will be null, or a String containing the input. null means that the dialog was cancelled and otherwise it
    // was confirmed!
    final Object? data = await _showDialogHelper(
      isLoadingDialog: false,
      newCancelCallback: event.onCancel,
      dialogBuilder: (BuildContext context) => InputDialog(bloc: this, event: event),
    );
    if (data is (String, int)) {
      final (String text, int index) = data;
      event.onConfirm(text, index);
    }
    // the on cancel callback will be called automatically
  }

  Future<void> _handleShowSelectDialog(ShowSelectDialog event, Emitter<DialogOverlayState> emit) async {
    // the data will be null, or an int containing the index of the selected element. null means that the dialog was
    // cancelled and otherwise it was confirmed!
    final Object? data = await _showDialogHelper(
      isLoadingDialog: false,
      newCancelCallback: event.onCancel,
      dialogBuilder: (BuildContext context) => SelectionDialog(
        bloc: this,
        event: event,
        initialIndex: event.initialSelectedIndex,
      ),
    );
    if (data is int) {
      event.onConfirm(data);
    }
    // the on cancel callback will be called automatically
  }

  Future<void> _handleShowAboutDialog(ShowAboutDialog event, Emitter<DialogOverlayState> emit) async {
    Logger.verbose("Showing about dialog"); // special case
    if (loadingDialogCounter > 0) {
      _closeDialog(cancelDialog: false, isLoadingDialog: true, forceCloseLoadingDialog: true);
    }
    final TextStyle? style = Theme.of(context!).textTheme.bodyMedium;
    showAboutDialog(
      context: context!,
      applicationIcon: SvgPicture.asset(
        Assets.nota_letter_logo,
        height: 55,
        colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
      ),
      applicationName: "Nota",
      applicationVersion: "April 2023",
      applicationLegalese: "\u{a9} 2023 Nikoo00o",
      children: <Widget>[
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(style: style, text: translate("nota.about")),
              TextSpan(
                style: style?.copyWith(color: colors.primary),
                text: "https://github.com/Nikoo00o/Nota",
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse("https://github.com/Nikoo00o/Nota"), mode: LaunchMode.externalApplication);
                  },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a default text button that closes the dialog on a button press
  TextButton _buildTextButton({
    required String textKey,
    List<String>? textKeyParams,
    VoidCallback? onClick,
    ButtonStyle? style,
  }) {
    final Color color = colors.tertiary;
    late final ButtonStyle textButtonStyle;

    if (style != null) {
      if (style.foregroundColor != null) {
        textButtonStyle = style.copyWith(foregroundColor: MaterialStatePropertyAll<Color>(color));
      }
    } else {
      textButtonStyle = ButtonStyle(foregroundColor: MaterialStatePropertyAll<Color>(color));
    }

    return TextButton(
      style: textButtonStyle,
      onPressed: () {
        _closeDialog(cancelDialog: false);
        onClick?.call();
      },
      child: Text(translate(textKey, keyParams: textKeyParams)),
    );
  }

  /// Builds a default cancel button for the [event] for which the onCancel callback will also be called when the user
  /// navigates back!
  TextButton _buildCancelButton(_CancelDialog event) {
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
  ///
  /// The [newCancelCallback] should be set for all dialogs that have a cancel button which could have a custom action.
  /// And it will also be called when the user navigates back with the back button to close the dialog!
  Future<Object?> _showDialog({
    required String titleKey,
    List<String>? titleKeyParams,
    TextStyle? titleStyle,
    Widget? titleIcon,
    required Widget content,
    List<Widget> actions = const <Widget>[],
    bool isLoadingDialog = false,
    VoidCallback? newCancelCallback,
  }) async {
    return _showDialogHelper(
      isLoadingDialog: isLoadingDialog,
      newCancelCallback: newCancelCallback,
      dialogBuilder: (BuildContext context) => AlertDialog(
        icon: titleIcon,
        title: Text(translate(titleKey, keyParams: titleKeyParams)),
        titleTextStyle: titleStyle,
        content: SingleChildScrollView(child: content),
        actions: actions,
      ),
    );
  }

  /// Called from [_showDialog] and [_handleShowCustomDialog] to show the dialog. Look at [_showDialog] for details!
  Future<Object?> _showDialogHelper({
    required WidgetBuilder dialogBuilder,
    required bool isLoadingDialog,
    VoidCallback? newCancelCallback,
  }) async {
    if (_isDialogAlreadyVisible(isLoadingDialog: isLoadingDialog)) {
      return null;
    }
    if (isLoadingDialog) {
      Logger.spam("showing loading dialog");
    } else {
      Logger.verbose("showing custom dialog");
    }
    if (newCancelCallback != null) {
      _cancelCallback = newCancelCallback;
    }
    return showDialog(
      context: context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // the custom willpop is needed, because the dialog will be pushed with its own route and the default pages can
        // only receive the close events from the default routes of the materialapp
        return WillPopScope(onWillPop: () async => _onWillPop(context), child: dialogBuilder(context));
      },
    );
  }

  bool _isDialogAlreadyVisible({required bool isLoadingDialog}) {
    if (isLoadingDialog) {
      if (isCustomDialogVisible) {
        Logger.verbose("a base dialog is already open instead of a loading dialog");
        return true;
      }
      if (loadingDialogCounter++ > 0) {
        Logger.verbose("a loading dialog is already open, so only incremented: $loadingDialogCounter");
        return true;
      }
    } else {
      if (isCustomDialogVisible) {
        Logger.warn("a base dialog is already open");
        return true;
      } else if (loadingDialogCounter > 0) {
        Logger.verbose("closing loading dialog in favor of base dialog");
        _closeDialog(cancelDialog: false, isLoadingDialog: true, forceCloseLoadingDialog: true);
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
  ///
  /// [forceCloseLoadingDialog] will only be true when the loading dialog should be closed in favor of a base dialog
  void _closeDialog(
      {Object? dataForDialog,
      bool isLoadingDialog = false,
      required bool cancelDialog,
      bool forceCloseLoadingDialog = false}) {
    if (isLoadingDialog == false) {
      if (isCustomDialogVisible) {
        Logger.verbose("closing custom dialog with $dataForDialog");
        if (cancelDialog && _cancelCallback != null) {
          Logger.verbose("also calling the custom dialog cancel callback");
          _cancelCallback?.call();
        }
        _pop(dataForDialog);
        isCustomDialogVisible = false;
        _cancelCallback = null;
      } else {
        Logger.warn("tried to close an already closed custom dialog with $dataForDialog");
        _pop(dataForDialog);
      }
    }
    if (loadingDialogCounter > 0) {
      if ((--loadingDialogCounter <= 0 || forceCloseLoadingDialog) && isCustomDialogVisible == false) {
        Logger.spam("closing loading dialog");
        _pop(dataForDialog);
      } else {
        Logger.spam("only decrementing loading dialog $loadingDialogCounter");
      }
    } else if (isLoadingDialog && isCustomDialogVisible == false) {
      Logger.warn("tried to close an already closed loading dialog");
      _pop(dataForDialog);
    }
  }

  void _pop(Object? dataForDialog) {
    final NavigatorState navigator = Navigator.of(context!);
    if (navigator.canPop()) {
      navigator.pop(dataForDialog);
    }
  }

  /// Returns false if a custom back navigation was executed.
  /// Returns true if the app should navigate back (in most cases terminate the app).
  ///
  /// If a loading dialog is visible, then nothing will happen, but any other dialog will be cancelled!
  Future<bool> _onWillPop(BuildContext context) async {
    if (loadingDialogCounter > 0) {
      return false;
    } else if (isCustomDialogVisible) {
      _closeDialog(isLoadingDialog: false, dataForDialog: null, cancelDialog: true);
      return false;
    }
    return true;
  }

  String translate(String key, {List<String>? keyParams}) {
    return translationService.translate(key, keyParams: keyParams);
  }

  /// The build context of the dialog widget
  BuildContext? get context => dialogOverlayKey.currentContext;

  /// The colors of the theme
  ColorScheme get colors => Theme.of(context!).colorScheme;
}
