import 'dart:async';

import 'package:app/core/enums/routes.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/usecases/note_structure/navigation/navigate_to_item.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:app/presentation/pages/note_edit_file_wrapper/note_edit_file_state.dart';
import 'package:app/presentation/widgets/base_note/base_note_bloc.dart';
import 'package:app/presentation/widgets/base_note/note_popup_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

final class NoteEditFileBloc extends BaseNoteBloc<NoteEditFileState> {
  final NavigateToItem navigateToItem;
  final LoadNoteContent loadNoteContent;

  final ScrollController scrollController = ScrollController();

  /// the content of the file. this is null before initialization and otherwise it should always contain the
  /// correct data!
  NoteContentFileWrapper? content;

  NoteEditFileBloc({
    required super.navigationService,
    required super.dialogService,
    required super.appConfig,
    required super.appSettingsRepository,
    required super.getCurrentStructureItem,
    required super.getStructureUpdatesStream,
    required super.changeCurrentStructureItem,
    required super.startMoveStructureItem,
    required super.deleteCurrentStructureItem,
    required super.exportCurrentStructureItem,
    required super.isFavouriteUC,
    required super.changeFavourite,
    required this.navigateToItem,
    required this.loadNoteContent,
  }) : super(initialState: NoteEditFileState.initial());

  @override
  List<NoteDropDownMenuParam> get dropDownMenu {
    return <NoteDropDownMenuParam>[
      ...super.dropDownMenu,
      NoteDropDownMenuParam(
        isEnabled: true,
        translationString: TranslationString("note.selection.export"),
        callback: exportCurrentItem,
      ),
    ];
  }

  @override
  void registerEventHandlers() {
    super.registerEventHandlers(); // important: first register the super classes event handlers
  }

  @override
  Future<void> initialize() async {
    // currently nothing
  }

  @override
  Future<NoteEditFileState> buildState() async {
    if (currentItem is StructureNote) {
      // content will be loaded first in [onStructureChange]
      return NoteEditFileState(
        dropDownMenuParams: dropDownMenu,
        currentItem: currentItem,
        isFavourite: isFavourite,
        content: content,
      );
    } else {
      return NoteEditFileState.initial();
    }
  }

  @override
  Future<void> onUpdateState() async {
    // currently nothing
  }

  @override
  Future<bool> onStructureChange(StructureItem? oldItem) async {
    if (currentItem is StructureNote && currentItem!.noteType == NoteType.FILE_WRAPPER) {
      Logger.verbose("loading initial file content");
      final StructureNote note = currentItem as StructureNote;
      final NoteContent data = await loadNoteContent(LoadNoteContentParams(noteId: note.id, noteType: note.noteType));
      if (data is NoteContentFileWrapper) {
        content = data;
      } else {
        Logger.error("initial file content loading failed");
        throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
      }
      return true;
    } else {
      Logger.verbose("navigated away from note edit, because the note type is different");
      // will be called automatically from the structure change of _handleNavigatedBack
      navigationService.navigateTo(Routes.note_selection);
      return false;
    }
  }

  @override
  Future<bool> onBackNavigationShouldPop() async {
    Logger.verbose("navigated back to ${currentItem?.getParent()?.path}");
    await navigateToItem.call(const NavigateToItemParamsParent());
    return false; // no navigator pop is needed here !
  }
}
