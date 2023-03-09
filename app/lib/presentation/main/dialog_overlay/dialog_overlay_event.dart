import 'package:app/presentation/widgets/base_pages/page_event.dart';
import 'package:flutter/material.dart';

abstract class DialogOverlayEvent extends PageEvent {
  const DialogOverlayEvent();
}

abstract class _BaseDialog extends DialogOverlayEvent {
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
class ShowLoadingDialog extends DialogOverlayEvent {
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

/// Shows a customized dialog with a title, a custom body [content] and a list of custom [buttons] widgets.
///
/// Remember that every button has to add a [HideDialog] event to close the dialog!
class ShowCustomDialog extends _BaseDialog {
  final Widget content;
  final List<Widget> buttons;

  const ShowCustomDialog({
    required String titleKey,
    super.titleKeyParams,
    super.titleStyle,
    super.titleIcon,
    required this.content,
    required this.buttons,
  }) : super(titleKey: titleKey);
}

/// Shows a small info [SnackBar] at the bottom of the screen. this should only be used for small status updates.
/// For bigger more relevant info, use [ShowInfoDialog].
class ShowInfoSnackBar extends DialogOverlayEvent {
  final String textKey;
  final List<String>? textKeyParams;
  final TextStyle? textStyle;

  const ShowInfoSnackBar({
    required this.textKey,
    this.textKeyParams,
    this.textStyle,
  });
}

/// Shows an information dialog with a title, text and a confirm button. If the information is meaningless and small,
/// consider using [ShowInfoSnackBar] instead!
class ShowInfoDialog extends _BaseDialog {
  final String descriptionKey;
  final List<String>? descriptionKeyParams;
  final TextStyle? descriptionStyle;
  final String? confirmButtonKey;
  final List<String>? confirmButtonKeyParams;
  final ButtonStyle? confirmButtonStyle;

  /// Callback that gets called when the confirm button of the dialog was pressed
  final VoidCallback? onConfirm;

  const ShowInfoDialog({
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
    this.onConfirm,
  });
}

/// Hides both loading and custom dialog if visible
class HideDialog extends DialogOverlayEvent {
  final Object? dataForDialog;

  const HideDialog({this.dataForDialog});
}

/// Only hides the current loading dialog if no custom dialog is visible!
class HideLoadingDialog extends DialogOverlayEvent {
  const HideLoadingDialog();
}
