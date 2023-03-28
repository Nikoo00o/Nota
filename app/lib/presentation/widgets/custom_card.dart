import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomCard extends WidgetBase {
  final Color color;
  final VoidCallback? onTap;
  final IconData icon;

  /// Optional smaller icon displayed at the right side
  final IconData? trailingIcon;

  /// The title (already translated value!)
  final String title;

  /// tooltip on long press if not null
  final String? toolTip;

  /// The description (already translated value!)
  final String description;

  /// If the description should be put in the bottom right corner
  final bool alignDescriptionRight;

  static const double iconSize = 30;

  static const double trailingIconSize = 24;

  const CustomCard({
    super.key,
    required this.color,
    required this.onTap,
    required this.icon,
    required this.title,
    this.toolTip,
    required this.description,
    required this.alignDescriptionRight,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        // rebuild ink will with on tap depending on title to prevent click feedback after navigation!
        key: ValueKey<String>(title),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: _buildTooltipContainer(context),
      ),
    );
  }

  Widget _buildTooltipContainer(BuildContext context) {
    if (toolTip != null) {
      return Tooltip(
        message: toolTip,
        triggerMode: TooltipTriggerMode.longPress,
        child: _buildInner(context),
      );
    } else {
      return _buildInner(context);
    }
  }

  Widget _buildInner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: iconSize,
                color: colorOnSurface(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textTitleMedium(context).copyWith(color: colorOnSurfaceVariant(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  size: trailingIconSize,
                  color: colorOnSurfaceVariant(context),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: alignDescriptionRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  description,
                  textAlign: alignDescriptionRight ? TextAlign.right : TextAlign.left,
                  style: theme(context).textTheme.labelSmall?.copyWith(color: colorOnSurfaceVariant(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
