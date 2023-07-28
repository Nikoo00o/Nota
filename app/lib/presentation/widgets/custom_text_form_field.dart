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

  /// called with the current text when the user enters something with the keyboard
  final ValueChanged<String>? onChanged;

  /// called when the user presses the confirm button on the keyboard
  final VoidCallback? onConfirm;

  /// can be used to limit the keyboard
  final TextInputType? keyboardType;

  /// used to control focus of the text field
  final FocusNode? focusNode;

  /// if this text field should be focused automatically
  final bool autoFocus;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.validator,
    this.obscureText = false,
    required this.textKey,
    this.textKeyParams,
    this.onChanged,
    this.onConfirm,
    this.keyboardType,
    this.focusNode,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      autofocus: autoFocus,
      keyboardType: keyboardType,
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      onChanged: onChanged,
      onEditingComplete: onConfirm,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        labelText: translate(context, textKey, keyParams: textKeyParams),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
