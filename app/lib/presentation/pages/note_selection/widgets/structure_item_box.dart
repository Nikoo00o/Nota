import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_card.dart';
import 'package:flutter/material.dart';

class StructureItemBox extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
  final StructureItem item;
  final int index;
  static const double iconSize = 30;

  const StructureItemBox({
    required this.item,
    required this.index,
  });

  @override
  Widget buildWithNoState(BuildContext context, Widget partWithState) {
    return createBlocSelector<String?>(selector: (NoteSelectionState state) {
      if (state is NoteSelectionStateInitialised) {
        return state.searchInput;
      }
      return null;
    }, builder: (BuildContext context, String? searchString) {
      return createBlocSelector<Map<int, String>?>(selector: (NoteSelectionState state) {
        if (state is NoteSelectionStateInitialised) {
          return state.noteContentMap;
        }
        return null;
      }, builder: (BuildContext context, Map<int, String>? noteContentMap) {
        return _buildDependingOnSearch(context, searchString, noteContentMap);
      });
    });
  }

  Widget _buildDependingOnSearch(BuildContext context, String? searchString, Map<int, String>? noteContentMap) {
    if (searchString == null || item.containsName(searchString) || _containsNoteContent(searchString, noteContentMap)) {
      return CustomCard(
        color: item is StructureFolder ? colorSecondaryContainer(context) : colorPrimaryContainer(context),
        onTap: () => currentBloc(context).add(NoteSelectionItemClicked(index: index)),
        icon: item is StructureFolder ? Icons.folder : Icons.sticky_note_2_outlined,
        title: item.name,
        description: _getDescription(context),
        alignDescriptionRight: true,
      );
    }
    return const SizedBox();
  }

  bool _containsNoteContent(String? searchString, Map<int, String>? noteContentMap) {
    if (noteContentMap == null) {
      return false;
    }
    late final List<int> noteIds;
    if (item is StructureFolder) {
      noteIds = (item as StructureFolder).getAllNotes().map<int>((StructureNote note) => note.id).toList();
    } else {
      noteIds = <int>[(item as StructureNote).id];
    }
    for (final int id in noteIds) {
      final String? content = noteContentMap[id];
      if (content != null && searchString != null) {
        return content.contains(searchString);
      }
    }
    return false;
  }

  String _getDescription(BuildContext context) {
    if (item is StructureFolder) {
      if (item.topMostParent.isMove) {
        return "Select this folder";
      }
      if (item.lastModified.isBefore(DateTime.fromMillisecondsSinceEpoch(1))) {
        return translate(context, "note.selection.folder.needs.note");
      }
      return translate(context, "note.selection.folder.description", keyParams: <String>[item.lastModifiedFormatted]);
    } else {
      return translate(context, "note.selection.note.description", keyParams: <String>[item.lastModifiedFormatted]);
    }
  }
}
