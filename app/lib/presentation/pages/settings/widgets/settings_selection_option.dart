import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/pages/settings/widgets/settings_option.dart';
import 'package:app/services/dialog_service.dart';
import 'package:flutter/material.dart';

class SettingsSelectionOption extends SettingsOption {
  final List<TranslationString> options;
  final int? initialOptionIndex;
  final FutureOr<void> Function(int index) onSelected;

  final String? dialogTitleKey;
  final List<String>? dialogTitleKeyParams;
  final String? dialogDescriptionKey;
  final List<String>? dialogDescriptionKeyParams;

  const SettingsSelectionOption({
    required super.titleKey,
    super.titleKeyParams,
    super.descriptionKey,
    super.descriptionKeyParams,
    super.hasBigDescription = false,
    super.iconSize = 30,
    super.icon,
    super.disabled = false,
    required this.options,
    this.initialOptionIndex,
    required this.onSelected,
    this.dialogTitleKey,
    this.dialogTitleKeyParams,
    this.dialogDescriptionKey,
    this.dialogDescriptionKeyParams,
  });

  @override
  Widget? buildTrailing(BuildContext context) => null;

  @override
  void onTap(BuildContext context) {
    sl<DialogService>().showSelectionDialog(ShowSelectDialog(
      titleKey: dialogTitleKey,
      titleKeyParams: dialogTitleKeyParams,
      descriptionKey: dialogDescriptionKey,
      descriptionKeyParams: dialogDescriptionKeyParams,
      translationStrings: options,
      onConfirm: onSelected,
      initialSelectedIndex: initialOptionIndex,
    ));
  }
}
