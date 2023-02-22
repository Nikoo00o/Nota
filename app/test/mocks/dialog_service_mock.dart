import 'package:app/services/dialog_service.dart';

class DialogServiceMock extends DialogService {
  /// Used to mock the [showConfirmDialog] response
  bool confirmedOverride = false;

  @override
  void showErrorDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {}

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
}
