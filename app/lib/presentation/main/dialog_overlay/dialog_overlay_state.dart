import 'package:app/core/enums/dialog_status.dart';
import 'package:app/presentation/widgets/base_pages/page_state.dart';

class DialogOverlayState extends PageState {
  final DialogStatus dialogStatus;
  final String dialogTextKey;
  final List<String>? dialogTextKeyParams;
  final void Function()? navigationCallback;

  DialogOverlayState({
    this.dialogStatus = DialogStatus.HIDDEN,
    this.dialogTextKey = "",
    this.dialogTextKeyParams,
    this.navigationCallback,
  }) : super(<String, dynamic>{
          "dialogStatus": dialogStatus,
          "dialogTextKey": dialogTextKey,
          "dialogTextKeyParams": dialogTextKeyParams,
          "navigationCallback": navigationCallback,
        });
}
