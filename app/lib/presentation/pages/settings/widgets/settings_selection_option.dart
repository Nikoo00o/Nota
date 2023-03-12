import 'dart:async';

import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:app/services/dialog_service.dart';
import 'package:flutter/material.dart';

/// The dialog will have the same [titleKey]
class SettingsSelectionOption extends WidgetBase {
  final String titleKey;
  final List<String>? titleKeyParams;

  /// sub title if not null. if this is 2 lines, set [hasBigDescription] to true.
  final String? descriptionKey;
  final List<String>? descriptionKeyParams;
  final bool hasBigDescription;

  final double iconSize;

  /// leading icon if not null
  final IconData? icon;

  final List<TranslationString> options;
  final int? initialOptionIndex;
  final FutureOr<void> Function(int index) onSelected;

  final String? dialogTitleKey;
  final List<String>? dialogTitleKeyParams;
  final String? dialogDescriptionKey;
  final List<String>? dialogDescriptionKeyParams;

  const SettingsSelectionOption({
    required this.titleKey,
    this.titleKeyParams,
    this.descriptionKey,
    this.descriptionKeyParams,
    this.hasBigDescription = false,
    this.iconSize = 30,
    this.icon,
    required this.options,
    this.initialOptionIndex,
    required this.onSelected,
    this.dialogTitleKey,
    this.dialogTitleKeyParams,
    this.dialogDescriptionKey,
    this.dialogDescriptionKeyParams,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        leading: icon != null ? Icon(icon, size: iconSize) : null,
        minLeadingWidth: iconSize,
        isThreeLine: hasBigDescription,
        title: Text(translate(context, titleKey, keyParams: titleKeyParams)),
        subtitle: descriptionKey != null
            ? Text(translate(context, descriptionKey!, keyParams: descriptionKeyParams),
                style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)))
            : null,
        onTap: () => _openDialog(context),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
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
