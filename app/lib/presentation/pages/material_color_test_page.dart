import 'package:app/core/config/app_config.dart';
import 'package:app/core/config/app_theme.dart';
import 'package:app/core/constants/assets.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// This should be returned directly from the "build" method, because it only shows the splash screen as full screen!
  Widget _buildSplashScreen(BuildContext context) {
    return Scaffold(
      body: Stack(
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
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(title: const Text("Material Color Test"));
  }

  @override
  Widget? buildMenuDrawer(BuildContext context) {
    return Container(
      color: theme(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 3 / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text("Default Menu with the 'scaffoldBackgroundColor' color"),
          Text("AppBar has default color"),
          Text("The containers of the page have the 'background' color"),
        ],
      ),
    );
  }

  @override
  String get pageName => "Material Color Test";
}
