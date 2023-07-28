import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/settings/widgets/settings_option.dart';
import 'package:app/services/dialog_service.dart';
import 'package:flutter/material.dart';

class SettingsInputOption extends SettingsOption {
  /// used to display the resulting error message if the input is not valid.
  ///
  /// If this callback returns null, that means that there is no error.
  ///
  /// Otherwise this must return the already translated error message!!!
  final String? Function(String?)? validatorCallback;

  /// will be called with the input
  final FutureOr<void> Function(String input) onConfirm;

  final String? dialogTitleKey;
  final List<String>? dialogTitleKeyParams;
  final String? dialogDescriptionKey;
  final List<String>? dialogDescriptionKeyParams;
  final String? dialogInputLabelKey;

  /// can be used to limit the keyboard
  final TextInputType? keyboardType;

  /// if the input field should be focused when opening the dialog. Per default true
  final bool autoFocus;

  const SettingsInputOption({
    required super.titleKey,
    super.titleKeyParams,
    super.descriptionKey,
    super.descriptionKeyParams,
    super.hasBigDescription = false,
    super.iconSize = 30,
    super.icon,
    super.disabled = false,
    this.validatorCallback,
    required this.onConfirm,
    this.dialogTitleKey,
    this.dialogTitleKeyParams,
    this.dialogDescriptionKey,
    this.dialogDescriptionKeyParams,
    this.dialogInputLabelKey,
    this.keyboardType,
    this.autoFocus = true,
  });

  @override
  Widget? buildTrailing(BuildContext context) => null;

  @override
  void onTap(BuildContext context) {
    sl<DialogService>().showInputDialog(ShowInputDialog(
      titleKey: dialogTitleKey,
      titleKeyParams: dialogTitleKeyParams,
      descriptionKey: dialogDescriptionKey,
      descriptionKeyParams: dialogDescriptionKeyParams,
      onConfirm: onConfirm,
      validatorCallback: validatorCallback,
      keyboardType: keyboardType,
      inputLabelKey: dialogInputLabelKey,
      autoFocus: autoFocus,
    ));
  }
}
