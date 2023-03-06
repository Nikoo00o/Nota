import 'package:app/services/dialog_service.dart';

class DialogServiceMock extends DialogService {
  /// Used to mock the [showConfirmDialog] response if the user confirms the dialog, or not
  bool confirmedOverride = true;

  @override
  void showErrorDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {}

  @override
  void showInfoDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {}

  @override
  void showLoadingDialog({String? dialogTextKey, List<String>? dialogTextKeyParams}) {}

  @override
  Future<bool> showConfirmDialog({
    String? dialogTextKey,
    List<String>? dialogTextKeyParams,
    required String confirmTextKey,
    List<String>? confirmTextKeyParams,
    String? cancelTextKey,
    List<String>? cancelTextKeyParams,
  }) async {
    return confirmedOverride;
  }

  @override
  void hideDialog() {}

  @override
  void hideLoadingDialog() {}

  @override
  bool get isDialogVisible => false;

  @override
  bool get isLoading => false;
}
