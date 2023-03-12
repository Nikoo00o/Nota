import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends WidgetBase {
  /// The text editing controller which can be used to get the inputted text.
  final TextEditingController? controller;

  /// Callback that gets ONLY called by the text form field if there is a [Form] Widget build as a parent higher up in the
  /// widget tree!!!
  ///
  /// This can, but will mostly not be null.
  final FormFieldValidator<String>? validator;

  /// The text key used for translating a value.
  final String textKey;

  /// Params for [textKey]
  final List<String>? textKeyParams;

  /// Used for passwords
  final bool obscureText;

  final ValueChanged<String>? onChanged;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.validator,
    this.obscureText = false,
    required this.textKey,
    this.textKeyParams,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: translate(context, textKey, keyParams: textKeyParams),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
