class DialogService {

  /// Non blocking
  void showErrorDialog(String dialogTextKey, {List<String>? dialogTextKeyParams}) {
    // todo: implement dialogs and also prevent back navigation when dialogs are visible!!!
  }

  /// Non blocking
  void showLoadingDialog({String? dialogTextKey, List<String>? dialogTextKeyParams}) {}

  /// Shows a dialog with the [dialogTextKey] as description text if not null and otherwise a default "Confirm" message.
  /// If [cancelTextKey] is null, then the dialog will only have one button.
  ///
  /// Returns [true] if the [confirmTextKey] button was pressed and false if the [cancelTextKey] button was pressed.
  /// Blocks the calling function until the user pressed a button.
  Future<bool> showConfirmDialog({
    String? dialogTextKey,
    List<String>? dialogTextKeyParams,
    required String confirmTextKey,
    List<String>? confirmTextKeyParams,
    String? cancelTextKey,
    List<String>? cancelTextKeyParams,
  }) async {
    return true;
  }

  /// Hides the last dialog
  void hideDialog() {}
}
