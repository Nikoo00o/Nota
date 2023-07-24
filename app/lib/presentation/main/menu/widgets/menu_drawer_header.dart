import 'package:app/presentation/main/menu/menu_bloc.dart';
import 'package:app/presentation/main/menu/menu_event.dart';
import 'package:app/presentation/main/menu/menu_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/nota_icon.dart';
import 'package:flutter/material.dart';

final class MenuDrawerHeader extends BlocPageChild<MenuBloc, MenuState> {
  const MenuDrawerHeader();

  @override
  Widget buildWithState(BuildContext context, MenuState state) {
    if (state is MenuStateInitialised) {
      return Text(
        state.username ?? "",
        style: textTitleLarge(context).copyWith(color: colorSecondary(context)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox();
  }

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return SizedBox(
      height: 205,
      child: DrawerHeader(
        padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Column(
          children: <Widget>[
            const NotaIcon(imageSize: 66, fontSize: 24),
            ListTile(
              onTap: () => currentBloc(context).add(MenuUserProfileClicked()),
              contentPadding: const EdgeInsets.fromLTRB(6, 3, 8, 0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
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
