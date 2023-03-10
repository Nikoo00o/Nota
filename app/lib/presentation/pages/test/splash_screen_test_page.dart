import 'package:app/core/config/app_config.dart';
import 'package:app/core/config/app_theme.dart';
import 'package:app/core/constants/assets.dart';
import 'package:app/core/constants/routes.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/menu/logged_in_menu.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreenTestPage extends NoBlocPage {
  const SplashScreenTestPage() : super(pagePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0));

  @override
  Widget buildBody(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox.expand(
          child: Container(
            color: colorPrimaryContainer(context),
            child: SvgPicture.asset(
              Assets.note_bloc,
              colorFilter: ColorFilter.mode(colorOnPrimaryContainer(context), BlendMode.srcIn),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.85,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: colorBackground(context),
                    ),
                    child: SvgPicture.asset(
                      Assets.nota_letter_logo,
                      height: 220,
                      colorFilter: ColorFilter.mode(colorPrimary(context), BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Opacity(
              opacity: 1,
              child: Text(
                sl<AppConfig>().appTitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorPrimary(context), fontSize: 80),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<bool> customBackNavigation(BuildContext context) async {
    sl<NavigationService>().navigateTo(Routes.settings);
    return false;
  }

  @override
  String get pageName => "Splash Screen Test";
}
