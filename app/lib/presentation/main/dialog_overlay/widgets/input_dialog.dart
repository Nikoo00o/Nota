import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

/// This is the only dialog that is completely scrollable and wrapped inside of a center widget!
class InputDialog extends StatefulWidget {
  final DialogOverlayBloc bloc;
  final ShowInputDialog event;

  const InputDialog({
    required this.bloc,
    required this.event,
  });

  @override
  State<StatefulWidget> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  final TextEditingController controller = TextEditingController();
  bool _confirmButtonEnabled = false;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.event.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AlertDialog(
          icon: event.titleIcon,
          title: Text(translate(event.titleKey ?? "dialog.input.title", keyParams: event.titleKeyParams)),
          titleTextStyle: event.titleStyle,
          content: _buildContent(context),
          actions: <Widget>[
            _buildCancelButton(context),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SizedBox(
      // wider dialog
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (event.descriptionKey.isNotEmpty)
            Text(translate(event.descriptionKey, keyParams: event.descriptionKeyParams), style: event.descriptionStyle),
          if (event.descriptionKey.isNotEmpty) const SizedBox(height: 20),
          Form(
            autovalidateMode: AutovalidateMode.always,
            child: _buildFormField(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: event.validatorCallback,
      textKey: event.inputLabelKey ?? "dialog.input.label",
      keyboardType: event.keyboardType,
      onChanged: (String? input) {
        setState(() {
          if (input?.isEmpty ?? true) {
            _confirmButtonEnabled = false;
          } else {
            if (event.validatorCallback?.call(input) == null) {
              _confirmButtonEnabled = true;
            } else {
              _confirmButtonEnabled = false;
            }
          }
        });
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return _buildButton(
      textKey: event.cancelButtonKey ?? "dialog.button.cancel",
      textKeyParams: event.cancelButtonKeyParams,
      style: event.cancelButtonStyle,
      defaultColor: colors.tertiary,
      buttonEnabled: true,
      onClick: () => bloc.add(const HideDialog(cancelDialog: true)),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return _buildButton(
      textKey: event.confirmButtonKey ?? "dialog.button.confirm",
      textKeyParams: event.confirmButtonKeyParams,
      style: event.confirmButtonStyle,
      defaultColor: _confirmButtonEnabled ? colors.tertiary : Theme.of(context).disabledColor,
      buttonEnabled: _confirmButtonEnabled,
      onClick: () => bloc.add(HideDialog(dataForDialog: controller.text, cancelDialog: false)),
    );
  }

  Widget _buildButton({
    required String textKey,
    List<String>? textKeyParams,
    ButtonStyle? style,
    required Color defaultColor,
    required bool buttonEnabled,
    required VoidCallback onClick,
  }) {
    late final ButtonStyle textButtonStyle;
    if (style != null) {
      if (style.foregroundColor != null) {
        textButtonStyle = style.copyWith(foregroundColor: MaterialStatePropertyAll<Color>(defaultColor));
      }
    } else {
      textButtonStyle = ButtonStyle(foregroundColor: MaterialStatePropertyAll<Color>(defaultColor));
    }

    return TextButton(
      style: textButtonStyle,
      onPressed: buttonEnabled ? onClick : null,
      child: Text(translate(textKey, keyParams: textKeyParams)),
    );
  }

  DialogOverlayBloc get bloc => widget.bloc;

  ShowInputDialog get event => widget.event;

  String translate(String key, {List<String>? keyParams}) => bloc.translate(key, keyParams: keyParams);

  /// The colors of the theme
  ColorScheme get colors => Theme.of(context).colorScheme;
}
