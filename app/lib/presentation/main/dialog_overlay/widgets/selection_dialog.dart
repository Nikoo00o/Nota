import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:flutter/material.dart';

/// This dialog and the selection dialog are a bit bigger than the others
class SelectionDialog extends StatefulWidget {
  final DialogOverlayBloc bloc;
  final ShowSelectDialog event;
  final int? initialIndex;

  const SelectionDialog({
    required this.bloc,
    required this.event,
    required this.initialIndex,
  });

  @override
  State<StatefulWidget> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  late bool _confirmButtonEnabled;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _confirmButtonEnabled = selectedIndex != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: event.titleIcon,
      title: Text(translate(event.titleKey ?? "dialog.select.title", keyParams: event.titleKeyParams)),
      titleTextStyle: event.titleStyle,
      content: _buildContent(context),
      actions: <Widget>[
        _buildCancelButton(context),
        _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return SizedBox(
      // wider dialog
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(translate(event.descriptionKey, keyParams: event.descriptionKeyParams), style: event.descriptionStyle),
          const SizedBox(height: 10),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  event.translationStrings.length,
                  (int index) => _buildElement(context, index),
                ),
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildElement(BuildContext context, int index) {
    final TranslationString translationString = event.translationStrings[index];
    return RadioListTile<int?>(
      dense: true,
      title: Text(
        translate(translationString.translationKey, keyParams: translationString.translationKeyParams),
        style: event.descriptionStyle,
      ),
      value: index,
      groupValue: selectedIndex,
      onChanged: (int? value) {
        setState(() {
          selectedIndex = value;
          _confirmButtonEnabled = selectedIndex != null;
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
      onClick: () => bloc.add(const HideDialog(cancelDialog: false)),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return _buildButton(
      textKey: event.confirmButtonKey ?? "dialog.button.confirm",
      textKeyParams: event.confirmButtonKeyParams,
      style: event.confirmButtonStyle,
      defaultColor: _confirmButtonEnabled ? colors.tertiary : Theme.of(context).disabledColor,
      buttonEnabled: _confirmButtonEnabled,
      onClick: () => bloc.add(HideDialog(dataForDialog: selectedIndex, cancelDialog: false)),
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

  ShowSelectDialog get event => widget.event;

  String translate(String key, {List<String>? keyParams}) => bloc.translate(key, keyParams: keyParams);

  /// The colors of the theme
  ColorScheme get colors => Theme.of(context).colorScheme;
}
