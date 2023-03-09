import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomOutlinedButton extends WidgetBase {
  final VoidCallback? onPressed;

  /// The text key used for translating a value
  final String textKey;

  /// Params for [textKey]
  final List<String>? textKeyParams;

  /// If the color is null, then the primary color will be used
  final Color? color;

  const CustomOutlinedButton({
    super.key,
    this.onPressed,
    required this.textKey,
    this.color,
    this.textKeyParams,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorToUse = color ?? colorPrimary(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(colorToUse),
        side: MaterialStateProperty.all(
          BorderSide(
            style: BorderStyle.solid,
            width: 1,
            color: colorToUse,
          ),
        ),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
      ),
      child: Text(translate(textKey, keyParams: textKeyParams)),
    );
  }
}
