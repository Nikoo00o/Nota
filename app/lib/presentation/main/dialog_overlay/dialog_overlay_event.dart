import 'package:app/presentation/widgets/base_pages/page_event.dart';

abstract class DialogOverlayEvent extends PageEvent {
  const DialogOverlayEvent();
}

class ShowLoadingDialog extends DialogOverlayEvent {
  final String? dialogTextKey;
  final List<String>? dialogTextKeyParams;

  const ShowLoadingDialog(this.dialogTextKey, this.dialogTextKeyParams);
}

class ShowErrorDialog extends DialogOverlayEvent {
  final String dialogTextKey;
  final List<String>? dialogTextKeyParams;

  const ShowErrorDialog(this.dialogTextKey, this.dialogTextKeyParams);
}

class ShowConfirmDialog extends DialogOverlayEvent {
  final String dialogTextKey;
  final List<String>? dialogTextKeyParams;
  final void Function() navigationCallback;

  const ShowConfirmDialog(this.dialogTextKey, this.dialogTextKeyParams, this.navigationCallback);
}

class HideDialog extends DialogOverlayEvent {
  const HideDialog();
}
