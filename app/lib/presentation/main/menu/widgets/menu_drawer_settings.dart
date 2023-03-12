import 'package:app/presentation/main/menu/widgets/menu_item.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';

class MenuDrawerSettings extends WidgetBase {
  const MenuDrawerSettings();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        MenuItem(pageTitleKey: "page.settings.title"),
        MenuItem(pageTitleKey: "menu.lock.screen.title"),
        MenuItem(pageTitleKey: "menu.logout.title"),
        MenuItem(pageTitleKey: "menu.about"),
      ],
    );
  }
}
