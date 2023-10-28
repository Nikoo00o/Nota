import 'dart:convert';
import 'package:app/core/config/app_config.dart';
import 'package:app/domain/entities/note_content/note_content.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This decrypts and loads the content of all notes of [NoteStructureRepository.root] mapped to their ids.
///
/// The content of the notes will be displayed in lower case (for easy search matching) if
/// [AppConfig.searchCaseSensitive] is false
///
/// This can throw the exceptions of [LoadNoteContent]!
///
/// But this can also throw an out of memory exception if the user has too many big notes stored!
class LoadAllStructureContent extends UseCase<Map<int, String>, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final LoadNoteContent loadNoteContent;
  final AppConfig appConfig;

  const LoadAllStructureContent({
    required this.noteStructureRepository,
    required this.loadNoteContent,
    required this.appConfig,
  });

  @override
  Future<Map<int, String>> execute(NoParams params) async {
    final Map<int, String> result = <int, String>{};
    if (noteStructureRepository.root != null) {
      final List<StructureNote> notes = noteStructureRepository.root!.getAllNotes();
      for (final StructureNote note in notes) {
        final NoteContent content =
            await loadNoteContent(LoadNoteContentParams(noteId: note.id, noteType: note.noteType));
        if (appConfig.searchCaseSensitive) {
          result[note.id] = utf8.decode(content.text);
        } else {
          result[note.id] = utf8.decode(content.text).toLowerCase();
        }
      }
    }
    Logger.verbose("Loaded and decrypted the content for ${result.length} notes");
    return result;
  }
}
