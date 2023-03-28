import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomIconButton extends WidgetBase {
  final IconData icon;

  /// this will be called when the button is [enabled] and pressed
  final VoidCallback onPressed;

  /// this will be called when the button is not [enabled] and pressed.
  final VoidCallback? onDisabledPress;
  final bool enabled;
  final CustomIconButtonType buttonType;
  final EdgeInsets? padding;
  final double? size;
  final String? tooltipKey;
  final List<String>? tooltipKeyParams;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.onDisabledPress,
    this.enabled = true,
    this.buttonType = CustomIconButtonType.DEFAULT,
    this.padding,
    this.size,
    this.tooltipKey,
    this.tooltipKeyParams,
  });

  @override
  Widget build(BuildContext context) {
    switch (buttonType) {
      case CustomIconButtonType.FILLED:
        return _buildFilled(context);
      case CustomIconButtonType.FILLED_SECONDARY:
        return _buildFilledSecondary(context);
      case CustomIconButtonType.FILLED_TERTIARY:
        return _buildFilledTertiary(context);
      case CustomIconButtonType.FILLED_TONAL:
        return _buildFilledTonal(context);
      case CustomIconButtonType.OUTLINED:
        return _buildOutlined(context);
      default:
        return _buildDefault(context, null);
    }
  }

  Widget _buildFilled(BuildContext context) {
    return _buildDefault(
      context,
      IconButton.styleFrom(
        foregroundColor: colorOnPrimary(context),
        backgroundColor: colorPrimary(context),
        disabledBackgroundColor: colorOnSurface(context).withOpacity(0.12),
        hoverColor: colorOnPrimary(context).withOpacity(0.08),
        focusColor: colorOnPrimary(context).withOpacity(0.12),
        highlightColor: colorOnPrimary(context).withOpacity(0.12),
      ),
    );
  }

  Widget _buildFilledSecondary(BuildContext context) {
    return _buildDefault(
      context,
      IconButton.styleFrom(
        foregroundColor: colorOnSecondary(context),
        backgroundColor: colorSecondary(context),
        disabledBackgroundColor: colorOnSurface(context).withOpacity(0.12),
        hoverColor: colorOnSecondary(context).withOpacity(0.08),
        focusColor: colorOnSecondary(context).withOpacity(0.12),
        highlightColor: colorOnSecondary(context).withOpacity(0.12),
      ),
    );
  }

  Widget _buildFilledTertiary(BuildContext context) {
    return _buildDefault(
      context,
      IconButton.styleFrom(
        foregroundColor: colorOnTertiary(context),
        backgroundColor: colorTertiary(context),
        disabledBackgroundColor: colorOnSurface(context).withOpacity(0.12),
        hoverColor: colorOnTertiary(context).withOpacity(0.08),
        focusColor: colorOnTertiary(context).withOpacity(0.12),
        highlightColor: colorOnTertiary(context).withOpacity(0.12),
      ),
    );
  }

  Widget _buildFilledTonal(BuildContext context) {
    return _buildDefault(
      context,
      IconButton.styleFrom(
        foregroundColor: colorOnSecondaryContainer(context),
        backgroundColor: colorSecondaryContainer(context),
        disabledBackgroundColor: colorOnSurface(context).withOpacity(0.12),
        hoverColor: colorOnSecondaryContainer(context).withOpacity(0.08),
        focusColor: colorOnSecondaryContainer(context).withOpacity(0.12),
        highlightColor: colorOnSecondaryContainer(context).withOpacity(0.12),
      ),
    );
  }

  Widget _buildOutlined(BuildContext context) {
    return _buildDefault(
      context,
      IconButton.styleFrom(
        focusColor: colorOnSurfaceVariant(context).withOpacity(0.12),
        highlightColor: colorOnSurface(context).withOpacity(0.12),
        side: enabled == false
            ? BorderSide(color: colorOnSurface(context).withOpacity(0.12))
            : BorderSide(color: colorOutline(context)),
      ).copyWith(
        foregroundColor: MaterialStateProperty.resolveWith((Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return colorOnSurface(context);
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildDefault(BuildContext context, ButtonStyle? style) {
    if (enabled) {
      return IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: size,
        padding: padding,
        style: style,
        tooltip: tooltipKey == null ? null : translate(context, tooltipKey!, keyParams: tooltipKeyParams),
      );
    } else {
      return GestureDetector(
        onTap: onDisabledPress,
        child: IconButton(
          icon: Icon(icon),
          onPressed: null,
          iconSize: size,
          padding: padding,
          style: style,
          tooltip: tooltipKey == null ? null : translate(context, tooltipKey!, keyParams: tooltipKeyParams),
        ),
      );
    }
  }
}
