import 'package:app/core/config/app_config.dart';
import 'package:app/core/get_it.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/presentation/pages/note_selection/note_selection_bloc.dart';
import 'package:app/presentation/pages/note_selection/note_selection_event.dart';
import 'package:app/presentation/pages/note_selection/note_selection_state.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page_child.dart';
import 'package:app/presentation/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/enums/note_type.dart';

/// The notes / folders that can be selected
final class StructureItemBox extends BlocPageChild<NoteSelectionBloc, NoteSelectionState> {
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
        return createBlocSelector<DateTime>(selector: (NoteSelectionState state) {
          if (state is NoteSelectionStateInitialised) {
            return state.lastNoteTransferTime;
          }
          return DateTime.fromMillisecondsSinceEpoch(0);
        }, builder: (BuildContext context, DateTime lastNoteTransferTime) {
          return _buildDependingOnSearch(context, searchString, noteContentMap, lastNoteTransferTime);
        });
      });
    });
  }

  Widget _buildDependingOnSearch(
    BuildContext context,
    String? searchString,
    Map<int, String>? noteContentMap,
    DateTime lastNoteTransferTime,
  ) {
    if (searchString == null ||
        item.containsName(searchString, caseSensitive: getIt<AppConfig>().searchCaseSensitive) ||
        _containsNoteContent(searchString, noteContentMap)) {
      return CustomCard(
        color: switch (item.noteType) {
          NoteType.FOLDER => colorSecondaryContainer(context),
          NoteType.RAW_TEXT => colorPrimaryContainer(context),
          NoteType.FILE_WRAPPER => colorInversePrimary(context),
        },
        onTap: () => currentBloc(context).add(NoteSelectionItemClicked(index: index)),
        icon: switch (item.noteType) {
          NoteType.FOLDER => Icons.folder,
          NoteType.RAW_TEXT => Icons.sticky_note_2_outlined,
          NoteType.FILE_WRAPPER => Icons.file_present_outlined,
        },
        trailingIcon: item.lastModified.isBefore(lastNoteTransferTime) ? null : Icons.sync_problem,
        title: item.name,
        description: _getDescription(context),
        alignDescriptionRight: true,
        parentPath: _extraPathInfoLine(item, context),
      );
    }
    return const SizedBox();
  }

  /// for the notes.recent view this will display another description line for the parent path with a leading "/"
  String? _extraPathInfoLine(final StructureItem item, BuildContext context) {
    if (item.topMostParent.isRecent == false) {
      return null;
    }
    if (item.directParent?.isRecent ?? false) {
      return translate(context, "note.edit.path", keyParams: <String>["/"]);
    }
    return translate(context, "note.edit.path", keyParams: <String>["/${item.directParent?.path}"]);
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
        if (content.contains(searchString)) {
          return true;
        }
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
