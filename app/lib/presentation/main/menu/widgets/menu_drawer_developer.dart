import 'package:app/presentation/main/menu/widgets/menu_item.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class MenuDrawerDeveloper extends WidgetBase {
  const MenuDrawerDeveloper();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        MenuItem(pageTitleKey: "page.dialog.test.title"),
        MenuItem(pageTitleKey: "page.material.color.test.title"),
        MenuItem(pageTitleKey: "page.splash.screen.test.title"),
      ],
    );
  }
}
