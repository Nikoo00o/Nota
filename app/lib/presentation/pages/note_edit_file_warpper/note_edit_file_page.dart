import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_edit/widgets/note_bottom_bar.dart';
import 'package:app/presentation/pages/note_edit_file_warpper/note_edit_file_bloc.dart';
import 'package:app/presentation/pages/note_edit_file_warpper/note_edit_file_state.dart';
import 'package:app/presentation/widgets/base_note/base_note_page.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';

final class NoteEditFilePage extends BaseNotePage<NoteEditFileBloc, NoteEditFileState> {
  const NoteEditFilePage() : super(pagePadding: EdgeInsets.zero);

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(
      controller: currentBloc(context).scrollController,
      child: createBlocBuilder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context, NoteEditFileState state) {
    if (state.isInitialized) {
      return Column(
        children: <Widget>[
          Text(state.currentItem?.path ?? ""),
          Text(state.content?.path ?? ""),
          Text(state.content?.fileExtension ?? ""),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return PreferredSize(
      // default size
      preferredSize: const Size.fromHeight(BlocPage.defaultAppBarHeight),
      child: createBlocSelector<StructureItem?>(
        selector: (NoteEditFileState state) => state.currentItem,
        builder: (BuildContext context, StructureItem? currentItem) {
          if (currentItem == null) {
            return AppBar(); // use empty app bar at first, so that the element gets cached for performance
          } else {
            return buildTitleAppBar(context, currentItem, withBackButton: true);
          }
        },
      ),
    );
  }

  @override
  Widget buildBottomBar(BuildContext context) => const NoteBottomBar<NoteEditFileBloc, NoteEditFileState>();

  @override
  String get pageName => "note edit file";
}
