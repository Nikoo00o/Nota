import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/presentation/widgets/custom_text_form_field.dart';
import 'package:app/services/dialog_service.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';

class DialogTestPage extends NoBlocPage {
  const DialogTestPage() : super(pagePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0));

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilledButton(
            onPressed: () {
              sl<DialogService>().show(const ShowInfoSnackBar(textKey: "some long long info text yay"));
            },
            child: const Text("test snack"),
          ),
          FilledButton(
            onPressed: () {
              sl<DialogService>().show(const ShowInfoDialog(descriptionKey: "some long description, yay"));
            },
            child: const Text("test info dialog"),
          ),
          FilledButton(
            onPressed: () async {
              sl<DialogService>().show(const ShowLoadingDialog());
              await Future<void>.delayed(const Duration(seconds: 4));
              sl<DialogService>().show(const HideLoadingDialog());
            },
            child: const Text("test loading dialog"),
          ),
          FilledButton(
            onPressed: () async {
              sl<DialogService>().show(const ShowErrorDialog(descriptionKey: "errorrororororoor"));
            },
            child: const Text("test error dialog "),
          ),
          FilledButton(
            onPressed: () async {
              sl<DialogService>().show(ShowConfirmDialog(
                descriptionKey: "confirm this",
                onConfirm: () {
                  Logger.verbose("CONFIRMED");
                },
                onCancel: () {
                  Logger.verbose("CANCELLED");
                },
              ));
            },
            child: const Text("test confirm dialog "),
          ),
          FilledButton(
            onPressed: () async {
              sl<DialogService>().show(ShowInputDialog(
                descriptionKey: "input at least 4 characters",
                onConfirm: (String data) {
                  Logger.verbose("CONFIRMED $data");
                },
                validatorCallback: (String? input) {
                  if (input != null && input.length < 4) {
                    return "more chars";
                  }
                  return null;
                },
                onCancel: () {
                  Logger.verbose("CANCELLED");
                },
              ));
            },
            child: const Text("test input dialog "),
          ),
          FilledButton(
            onPressed: () async {
              sl<DialogService>().show(ShowSelectDialog(
                translationStrings: <TranslationString>[
                  TranslationString("first"),
                  TranslationString("second"),
                  TranslationString("third"),
                  TranslationString("fourth"),
                  TranslationString("sixth"),
                  TranslationString("seventhseventhseventhseventhasdd"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                  TranslationString("seventh"),
                ],
                descriptionKey: "select something",
                onConfirm: (int index) {
                  Logger.verbose("CONFIRMED $index");
                },
                onCancel: () {
                  Logger.verbose("CANCELLED");
                },
              ));
            },
            child: const Text("test selection dialog "),
          ),
          const CustomTextFormField(textKey: "test input"),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        "Dialog Test",
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    return const LoggedInMenu(currentPageTranslationKey: "page.dialog.test.title");
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.note_selection);
    return false;
  }

  @override
  String get pageName => "Dialog Test";
}
