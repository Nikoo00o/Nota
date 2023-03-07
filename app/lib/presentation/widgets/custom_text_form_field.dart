import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends WidgetBase {
  /// The text editing controller which can be used to get the inputted text.
  final TextEditingController? controller;

  /// Callback that gets ONLY called by the text form field if there is a [Form] Widget build as a parent higher up in the
  /// widget tree!!!
  final FormFieldValidator<String>? validator;

  /// The text key used for translating a value.
  final String textKey;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.validator,
    required this.textKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: true,
      decoration: InputDecoration(
        labelText: translate(textKey),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
