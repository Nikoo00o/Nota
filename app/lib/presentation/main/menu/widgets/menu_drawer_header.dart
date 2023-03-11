import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
import 'package:flutter/material.dart';

class MenuDrawerHeader extends BlocPageChild<MenuBloc, MenuState> {
  const MenuDrawerHeader();

  @override
  Widget buildWithState(BuildContext context, MenuState state) {
    if (state is MenuStateInitialized) {
      return Text(
        state.userName ?? "",
        style: theme(context).textTheme.titleLarge?.copyWith(color: colorSecondary(context)),
        maxLines: 2,
      );
    }
    return const SizedBox();
  }

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return SizedBox(
      height: 205,
      child: DrawerHeader(
        padding: const EdgeInsets.fromLTRB(5, 20, 5, 5),
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Column(
          children: <Widget>[
            const NotaIcon(imageSize: 66, fontSize: 24),
            ListTile(
              leading: Icon(
                Icons.account_circle,
                size: 40,
                color: colorSecondary(context),
              ),
              minLeadingWidth: 40,
              title: partWithState,
            ),
          ],
        ),
      ),
    );
  }
}
