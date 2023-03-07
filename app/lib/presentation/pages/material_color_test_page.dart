import 'package:app/core/config/app_theme.dart';
import 'package:app/presentation/widgets/base_pages/no_bloc_page.dart';
import 'package:flutter/material.dart';

class MaterialColorTestPage extends NoBlocPage {
  const MaterialColorTestPage() : super(pagePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0));

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Theme(
            data: AppTheme.newTheme(darkTheme: true),
            child: Builder(
              builder: (BuildContext context) {
                return Container(
                  color: theme(context).colorScheme.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 5),
                      FilledButton(
                        onPressed: () {},
                        child: const Text("primary"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.primaryContainer),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onPrimaryContainer),
                        ),
                        child: const Text("primary container"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.secondary),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onSecondary),
                        ),
                        child: const Text("secondary"),
                      ),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text("secondary container"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.tertiary),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onTertiary),
                        ),
                        child: const Text("tertiary"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.tertiaryContainer),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onTertiaryContainer),
                        ),
                        child: const Text("tertiary container"),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                );
              },
            ),
          ),
          Theme(
            data: AppTheme.newTheme(darkTheme: false),
            child: Builder(
              builder: (BuildContext context) {
                return Container(
                  color: theme(context).colorScheme.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 5),
                      FilledButton(
                        onPressed: () {},
                        child: const Text("primary"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.primaryContainer),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onPrimaryContainer),
                        ),
                        child: const Text("primary container"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.secondary),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onSecondary),
                        ),
                        child: const Text("secondary"),
                      ),
                      FilledButton.tonal(
                        onPressed: () {},
                        child: const Text("secondary container"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.tertiary),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onTertiary),
                        ),
                        child: const Text("tertiary"),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(theme(context).colorScheme.tertiaryContainer),
                          foregroundColor: MaterialStateProperty.all(theme(context).colorScheme.onTertiaryContainer),
                        ),
                        child: const Text("tertiary container"),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                );
              },
            ),
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
      width: MediaQuery.of(context).size.width / 2,
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
