part of "dialog_overlay_bloc.dart";

/// For Documentation on how to use the dialogs, look at [DialogOverlayBloc].
sealed class DialogOverlayEvent extends PageEvent {
  const DialogOverlayEvent();
}

sealed class _BaseDialog extends DialogOverlayEvent {
  final String? titleKey;
  final List<String>? titleKeyParams;
  final TextStyle? titleStyle;
  final Widget? titleIcon;

  const _BaseDialog({
    this.titleKey,
    this.titleKeyParams,
    this.titleStyle,
    this.titleIcon,
  });
}

/// Shows a loading dialog with a title and a description and the loading indicator
final class ShowLoadingDialog extends DialogOverlayEvent {
  final String? titleKey;
  final List<String>? titleKeyParams;
  final String? descriptionKey;
  final List<String>? descriptionKeyParams;

  const ShowLoadingDialog({
    this.titleKey,
    this.titleKeyParams,
    this.descriptionKey,
    this.descriptionKeyParams,
  });
}

/// Shows a completely customizable dialog.
///
/// The [builder] should build an [AlertDialog] with its content and buttons. The cancel button should always be build first!
///
/// Remember that every button has to add a [HideDialog] event to the [DialogOverlayBloc] to close the dialog!!!!
/// You can call the hideDialog of the dialog service for that.
///
/// Also important: if the user presses the back button, the [onBackPressed] will be called and you should then cancel, or
/// hide your dialog!
///
/// The [onData] callback will be called with the data of the [HideDialog] event if there was any data.
///
/// If the dialog was cancelled, this callback will also additionally receive [null] as data.
final class ShowCustomDialog extends DialogOverlayEvent {
  final WidgetBuilder builder;
  final VoidCallback? onBackPressed;
  final FutureOr<void> Function(Object?)? onData;

  const ShowCustomDialog({required this.builder, this.onBackPressed, this.onData});
}

/// Shows a small info [SnackBar] at the bottom of the screen. this should only be used for small status updates.
/// For bigger more relevant info, use [ShowInfoDialog].
final class ShowInfoSnackBar extends DialogOverlayEvent {
  final String textKey;
  final List<String>? textKeyParams;
  final TextStyle? textStyle;
  /// Default is 4 seconds
  final Duration duration;

  const ShowInfoSnackBar({
    required this.textKey,
    this.textKeyParams,
    this.textStyle,
    this.duration = const Duration(seconds: 4),
  });
}

/// Does not include the on confirm callback!
final class _ConfirmDialog extends _BaseDialog {
  final String descriptionKey;
  final List<String>? descriptionKeyParams;
  final TextStyle? descriptionStyle;
  final String? confirmButtonKey;
  final List<String>? confirmButtonKeyParams;
  final ButtonStyle? confirmButtonStyle;

  const _ConfirmDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    required this.descriptionKey,
    this.descriptionKeyParams,
    this.descriptionStyle,
    this.confirmButtonKey,
    this.confirmButtonKeyParams,
    this.confirmButtonStyle,
  });
}

/// Shows an information dialog with a title, text and a confirm button. If the information is meaningless and small,
/// consider using [ShowInfoSnackBar] instead!
///
/// This is also used to display an error dialog!
final class ShowInfoDialog extends _ConfirmDialog {
  /// Callback that gets called when the confirm button of the dialog was pressed
  final VoidCallback? onConfirm;

  const ShowInfoDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    required super.descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    this.onConfirm,
  });
}

/// This is the same as [ShowInfoDialog] except that you should not set the [titleStyle] and the [titleKey] will also have
/// a different default value!
final class ShowErrorDialog extends _ConfirmDialog {
  /// Callback that gets called when the confirm button of the dialog was pressed
  final VoidCallback? onConfirm;

  const ShowErrorDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleIcon,
    required super.descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    this.onConfirm,
  });
}

/// Does not include the on confirm callback!
sealed class _CancelDialog extends _ConfirmDialog {
  final String? cancelButtonKey;
  final List<String>? cancelButtonKeyParams;
  final ButtonStyle? cancelButtonStyle;

  /// Callback that gets called when the cancel button of the dialog was pressed
  final VoidCallback? onCancel;

  const _CancelDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    required super.descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    this.cancelButtonKey,
    this.cancelButtonKeyParams,
    this.cancelButtonStyle,
    this.onCancel,
  });
}

/// Shows a confirm dialog with a title, text and a confirm button and also a cancel button.
final class ShowConfirmDialog extends _CancelDialog {
  /// Callback that gets called when the confirm button of the dialog was pressed
  final VoidCallback? onConfirm;

  const ShowConfirmDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    required super.descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    super.cancelButtonKey,
    super.cancelButtonKeyParams,
    super.cancelButtonStyle,
    super.onCancel,
    this.onConfirm,
  });
}

/// Shows an input dialog with a title, text and a confirm button and also a cancel button.
///
/// Below the text will be a text input field for some input from the user. The input will be returned inside of the
/// [onConfirm] callback!
///
/// You can also add a [validatorCallback] which prevents the user from clicking on the confirm button and also displays
/// a translated error message to the user if the input string contains invalid characters.
///
/// An empty input string will not trigger the validator, but will also disable the confirm button.
///
/// The [descriptionKey] is used for an additional description above the input if its not null.
/// The [inputLabelKey] combined with the [validatorCallback] are used to show a label around the input field.
final class ShowInputDialog extends _CancelDialog {
  final String? inputLabelKey;

  /// Callback that gets called when the confirm button of the dialog was pressed and also contains the data the user put in
  final FutureOr<void> Function(String) onConfirm;

  /// If this callback returns null, that means that there is no error.
  ///
  /// Otherwise this must return the already translated error message!!!
  final String? Function(String?)? validatorCallback;

  /// can be used to limit the keyboard
  final TextInputType? keyboardType;

  /// if the input field should be focused when opening the dialog
  final bool autoFocus;

  const ShowInputDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    String? descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    super.cancelButtonKey,
    super.cancelButtonKeyParams,
    super.cancelButtonStyle,
    super.onCancel,
    this.inputLabelKey,
    required this.onConfirm,
    this.validatorCallback,
    this.keyboardType,
    required this.autoFocus,
  }) : super(descriptionKey: descriptionKey ?? "");
}

/// Shows a selection dialog with a title, text and a confirm button and also a cancel button.
///
/// Below the text will be a list of options from the [translationStrings] for which the user
/// can choose one. The index of the selected  element will be returned inside of the [onConfirm] callback!
///
/// The [translationStrings] will be translated by the dialog.
///
/// The confirm button will only be clickable if one of the elements was selected
final class ShowSelectDialog extends _CancelDialog {
  /// The translation keys for the elements which will be translated!
  final List<TranslationString> translationStrings;

  /// Callback that gets called when the confirm button of the dialog was pressed and also contains the data the user put in
  final FutureOr<void> Function(int) onConfirm;

  /// Can be set to already have one element selected at the beginning
  final int? initialSelectedIndex;

  const ShowSelectDialog({
    super.titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    String? descriptionKey,
    super.descriptionKeyParams,
    super.descriptionStyle,
    super.confirmButtonKey,
    super.confirmButtonKeyParams,
    super.confirmButtonStyle,
    super.cancelButtonKey,
    super.cancelButtonKeyParams,
    super.cancelButtonStyle,
    super.onCancel,
    required this.translationStrings,
    required this.onConfirm,
    this.initialSelectedIndex,
  }) : super(descriptionKey: descriptionKey ?? "dialog.select.description");
}

/// Hides both loading and custom dialog if visible
final class HideDialog extends DialogOverlayEvent {
  final Object? dataForDialog;

  /// If this is true, then the custom onCancel callback of the dialog will be called as well.
  /// Otherwise it will not be called (for example internally after closing the dialog from the confirm button).
  ///
  /// Most of the time this will just be true!
  final bool cancelDialog;

  const HideDialog({this.dataForDialog, required this.cancelDialog});
}

/// Only hides the current loading dialog if no custom dialog is visible!
final class HideLoadingDialog extends DialogOverlayEvent {
  const HideLoadingDialog();
}

final class ShowAboutDialog extends DialogOverlayEvent {
  const ShowAboutDialog();
}
