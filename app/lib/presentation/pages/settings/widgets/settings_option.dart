import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

/// base settings option list tile
abstract class SettingsOption extends WidgetBase {
  final String titleKey;
  final List<String>? titleKeyParams;

  /// sub title if not null. if this is 2 lines, set [hasBigDescription] to true.
  final String? descriptionKey;
  final List<String>? descriptionKeyParams;
  final bool hasBigDescription;

  final double iconSize;

  /// leading icon if not null
  final IconData? icon;

  /// If this option is disabled
  final bool disabled;

  const SettingsOption({
    required this.titleKey,
    this.titleKeyParams,
    this.descriptionKey,
    this.descriptionKeyParams,
    this.hasBigDescription = false,
    this.iconSize = 30,
    this.icon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: ListTile(
        dense: false,
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        leading: icon != null ? SizedBox(height: double.infinity, child: Icon(icon, size: iconSize)) : null,
        minLeadingWidth: iconSize,
        isThreeLine: hasBigDescription,
        title: Text(
          translate(context, titleKey, keyParams: titleKeyParams),
          style: textTitleMedium(context),
        ),
        subtitle: _buildDescription(context),
        trailing: buildTrailing(context),
        enabled: disabled == false,
        onTap: disabled ? null : () => onTap(context),
      ),
    );
  }

  Widget? _buildDescription(BuildContext context) {
    late TextStyle style;
    if (disabled) {
      style = textBodySmall(context).copyWith(color: colorDisabled(context));
    } else {
      style = textBodySmall(context).copyWith(color: colorOnSurfaceVariant(context));
    }
    if (descriptionKey != null) {
      return Text(
        translate(context, descriptionKey!, keyParams: descriptionKeyParams),
        style: style,
      );
    } else {
      return null;
    }
  }

  /// Overridden in sub class
  Widget? buildTrailing(BuildContext context);

  /// Overridden in sub class
  void onTap(BuildContext context);
}
