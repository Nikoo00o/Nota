import 'package:app/core/enums/custom_icon_button_type.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomIconButton extends WidgetBase {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final CustomIconButtonType buttonType;
  final EdgeInsets? padding;
  final double? size;
  final String? tooltip;

  const CustomIconButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.buttonType = CustomIconButtonType.DEFAULT,
    this.padding,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    switch (buttonType) {
      case CustomIconButtonType.FILLED:
        return _buildFilled(context);
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
    return IconButton(
      icon: Icon(icon),
      onPressed: enabled ? onPressed : null,
      iconSize: size,
      padding: padding,
      style: style,
      tooltip: tooltip,
    );
  }
}
