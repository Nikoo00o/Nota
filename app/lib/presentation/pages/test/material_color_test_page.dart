import 'package:app/core/config/app_theme.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';

class MaterialColorTestPage extends NoBlocPage {
  const MaterialColorTestPage() : super(pagePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0));

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Theme(
            data: AppTheme.newTheme(darkTheme: true),
            child: Builder(
              builder: (BuildContext context) => _buildButtons(context, "dark"),
            ),
          ),
          Theme(
            data: AppTheme.newTheme(darkTheme: false),
            child: Builder(
              builder: (BuildContext context) => _buildButtons(context, "light"),
            ),
          ),
        ],
      ),
    );
  }

  /// Also builds container with background color
  Widget _buildButtons(BuildContext context, String theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      color: colorScaffoldBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                child: Text("primary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorPrimaryContainer(context)),
                  foregroundColor: MaterialStateProperty.all(colorInverseSurface(context)),
                ),
                child: const Text("primary container"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorInversePrimary(context)),
                  foregroundColor: MaterialStateProperty.all(colorInverseSurface(context)),
                ),
                child: const Text("inverse"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorSecondary(context)),
                  foregroundColor: MaterialStateProperty.all(colorOnSecondary(context)),
                ),
                child: Text("secondary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorSecondaryContainer(context)),
                  foregroundColor: MaterialStateProperty.all(colorOnSecondaryContainer(context)),
                ),
                child: const Text("secondary container"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorTertiary(context)),
                  foregroundColor: MaterialStateProperty.all(colorOnTertiary(context)),
                ),
                child: Text("tertiary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(colorTertiaryContainer(context)),
                  foregroundColor: MaterialStateProperty.all(colorOnTertiaryContainer(context)),
                ),
                child: const Text("tertiary container"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorError(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnError(context)),
                    ),
                    child: Text("error $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorErrorContainer(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnErrorContainer(context)),
                    ),
                    child: const Text("error container"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorSurface(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnSurface(context)),
                    ),
                    child: Text("surface $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorSurfaceVariant(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnSurfaceVariant(context)),
                    ),
                    child: const Text("surface variant"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorOutline(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnInverseSurface(context)),
                    ),
                    child: Text("outline $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(colorOutlineVariant(context)),
                      foregroundColor: MaterialStateProperty.all(colorOnInverseSurface(context)),
                    ),
                    child: const Text("outline variant "),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        "Material Color Test",
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
    );
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    return const LoggedInMenu(currentPageTranslationKey: "page.material.color.test.title");
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.note_selection);
    return false;
  }

  @override
  String get pageName => "Material Color Test";
}
