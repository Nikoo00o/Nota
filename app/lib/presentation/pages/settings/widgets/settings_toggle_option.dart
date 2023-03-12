import 'dart:async';

import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class SettingsToggleOption extends WidgetBase {
  final String titleKey;
  final List<String>? titleKeyParams;

  /// sub title if not null. if this is 2 lines, set [hasBigDescription] to true.
  final String? descriptionKey;
  final List<String>? descriptionKeyParams;
  final bool hasBigDescription;

  final double iconSize;

  /// leading icon if not null
  final IconData? icon;

  final bool isActive;
  final FutureOr<void> Function(bool active) onChange;

  const SettingsToggleOption({
    required this.titleKey,
    this.titleKeyParams,
    this.descriptionKey,
    this.descriptionKeyParams,
    this.hasBigDescription = false,
    this.iconSize = 30,
    this.icon,
    required this.isActive,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
        leading: icon != null ? Icon(icon, size: iconSize) : null,
        minLeadingWidth: iconSize,
        isThreeLine: hasBigDescription,
        title: Text(
          translate(context, titleKey, keyParams: titleKeyParams),
          style: theme(context).textTheme.titleMedium,
        ),
        subtitle: descriptionKey != null
            ? Text(translate(context, descriptionKey!, keyParams: descriptionKeyParams),
                style: theme(context).textTheme.bodySmall?.copyWith(color: colorOnSurfaceVariant(context)))
            : null,
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isActive,
            onChanged: onChange,
          ),
        ),
        onTap: () => onChange(!isActive),
      ),
    );

  }
}
