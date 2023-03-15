import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/translation_service.dart';
import 'package:shared/core/utils/logger/logger.dart';

class InputValidator {
  /// The password should contain at least 4 characters and it should contain at least one lowercase letter, one uppercase
  /// letter and one number. returns true if the password is valid
  static bool validatePassword(String password) =>
      password.length >= 4 &&
      RegExp(r"[A-Z]").hasMatch(password) &&
      RegExp(r"[a-z]").hasMatch(password) &&
      RegExp(r"\d").hasMatch(password);

  /// returns false on error. password strength and matching will only be checked if [confirmPassword] is not null!
  ///
  /// Shows matching error dialogs and returns true if the input is valid.
  static bool validateInput({String? username, required String password, String? confirmPassword}) {
    final bool fieldsAreNotEmpty =
        (username?.isNotEmpty ?? true) && password.isNotEmpty && (confirmPassword?.isNotEmpty ?? true);
    if (fieldsAreNotEmpty == false) {
      Logger.error("One of the login page input fields was empty");
      sl<DialogService>().show(const ShowErrorDialog(descriptionKey: "page.login.empty.params"));
      return false;
    }
    if (confirmPassword != null && InputValidator.validatePassword(password) == false) {
      Logger.error("The password was not secure enough");
      sl<DialogService>().show(const ShowErrorDialog(descriptionKey: "page.login.insecure.password"));
    }

    if (confirmPassword != null && password != confirmPassword) {
      Logger.error("The passwords did not match");
      sl<DialogService>().show(const ShowErrorDialog(descriptionKey: "page.login.no.password.match"));
      return false;
    }
    return true;
  }

  /// new name for structure note, or folder. [parent] only needs to be set if [isFolder] is true.
  ///
  /// Returns the translated error string
  static String? validateNewItem(String? name, {required bool isFolder, StructureFolder? parent}) {
    if (name == null || name.isEmpty) {
      return null;
    }
    try {
      StructureItem.throwErrorForName(name);
    } catch (_) {
      return sl<TranslationService>().translate("note.selection.create.invalid.name");
    }
    if (isFolder && parent?.getDirectFolderByName(name, deepCopy: false) != null) {
      return sl<TranslationService>().translate("note.selection.create.name.taken");
    }
    return null;
  }
}
