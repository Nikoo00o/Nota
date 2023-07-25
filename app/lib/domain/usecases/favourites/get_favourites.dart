import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/repositories/note_structure_repository.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This returns all favourites, but first also removes favourites that point to structure items which have been
/// removed/renamed!
///
/// Therefor this also uses [NoteStructureRepository.root] and might call [FetchNewNoteStructure]
class GetFavourites extends UseCase<Favourites, NoParams> {
  final AppSettingsRepository appSettingsRepository;
  final NoteStructureRepository noteStructureRepository;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const GetFavourites({
    required this.appSettingsRepository,
    required this.noteStructureRepository,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<Favourites> execute(NoParams params) async {
    final Favourites favourites = await appSettingsRepository.getFavourites();
    bool changed = false;

    if (noteStructureRepository.root == null) {
      await fetchNewNoteStructure.call(const NoParams());
    }

    for (int i = 0; i < favourites.favourites.length; ++i) {
      final Favourite favourite = favourites.favourites[i];
      if (favourite is NoteFavourite) {
        final StructureNote? note = noteStructureRepository.root!.getNoteById(favourite.id);
        if (note == null) {
          favourites.removeFavouriteById(favourite.id);
          i--;
          changed = true;
          Logger.debug("removed favourite for note id ${favourite.id}");
        }
      } else if (favourite is FolderFavourite) {
        final StructureFolder? folder = noteStructureRepository.root!.getFolderByPath(favourite.path, deepCopy: false);
        if (folder == null) {
          favourites.removeFavouriteByPath(favourite.path);
          i--;
          changed = true;
          Logger.debug("removed favourite for folder path ${favourite.path}");
        }
      }
    }

    if (changed) {
      await appSettingsRepository.setFavourites(favourites);
    }

    return favourites;
  }
}
