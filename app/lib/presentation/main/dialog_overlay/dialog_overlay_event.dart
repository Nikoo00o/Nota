import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class DialogOverlayEvent extends PageEvent {}

class ShowLoadingDialog extends DialogOverlayEvent {
  final String? dialogTextKey;
  final List<String>? dialogTextKeyParams;

  ShowLoadingDialog(this.dialogTextKey, this.dialogTextKeyParams);
}

class ShowErrorDialog extends DialogOverlayEvent {
  final String dialogTextKey;
  final List<String>? dialogTextKeyParams;

  ShowErrorDialog(this.dialogTextKey, this.dialogTextKeyParams);
}

class ShowConfirmDialog extends DialogOverlayEvent {
  final String dialogTextKey;
  final List<String>? dialogTextKeyParams;
  final void Function() navigationCallback;

  ShowConfirmDialog(this.dialogTextKey, this.dialogTextKeyParams, this.navigationCallback);
}

class HideDialog extends DialogOverlayEvent {}
