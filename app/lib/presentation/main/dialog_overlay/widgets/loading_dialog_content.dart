import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class LoadingDialogContent extends WidgetBase {
  final String? descriptionKey;
  final List<String>? descriptionKeyParams;

  const LoadingDialogContent({
    this.descriptionKey,
    this.descriptionKeyParams,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 20.0),
        SizedBox(
          height: 60.0,
          width: 60.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorOnBackground(context)),
          ),
        ),
        const SizedBox(height: 30.0),
        Text(translate(context, descriptionKey ?? "dialog.loading.description", keyParams: descriptionKeyParams)),
      ],
    );
  }
}
