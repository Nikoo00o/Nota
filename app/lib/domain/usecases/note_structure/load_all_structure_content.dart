import 'dart:convert';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_transfer/load_note_content.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This decrypts and loads the content of all notes of [NoteStructureRepository.root] mapped to their ids.
///
/// This can throw the exceptions of [LoadNoteContent]!
///
/// But this can also throw an out of memory exception if the user has too many big notes stored!
class LoadAllStructureContent extends UseCase<Map<int, String>, NoParams> {
  final NoteStructureRepository noteStructureRepository;
  final LoadNoteContent loadNoteContent;

  const LoadAllStructureContent({required this.noteStructureRepository, required this.loadNoteContent});

  @override
  Future<Map<int, String>> execute(NoParams params) async {
    final Map<int, String> result = <int, String>{};
    if (noteStructureRepository.root != null) {
      final List<StructureNote> notes = noteStructureRepository.root!.getAllNotes();
      for (final StructureNote note in notes) {
        final List<int> decryptedBytes = await loadNoteContent(LoadNoteContentParams(noteId: note.id));
        result[note.id] = utf8.decode(decryptedBytes);
      }
    }
    Logger.verbose("Loaded and decrypted the content for ${result.length} notes");
    return result;
  }
}
