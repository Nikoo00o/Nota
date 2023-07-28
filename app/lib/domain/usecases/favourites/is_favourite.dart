import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:shared/domain/usecases/usecase.dart';

class IsFavourite extends UseCase<bool, IsFavouriteParams> {
  final AppSettingsRepository appSettingsRepository;

  const IsFavourite({
    required this.appSettingsRepository,
  });

  @override
  Future<bool> execute(IsFavouriteParams params) async {
    final Favourites favourites = await appSettingsRepository.getFavourites();
    if (params.item != null) {
      return favourites.isFavourite(params.item!);
    } else {
      return favourites.isNoteFavourite(params.noteId!);
    }
  }
}

/// one of the two members is not null, but both are never set!
class IsFavouriteParams {
  /// The affected structure item
  final StructureItem? item;

  /// The id of a note
  final int? noteId;

  IsFavouriteParams.fromItem(StructureItem this.item) : noteId = null;

  IsFavouriteParams.fromNoteId(int this.noteId) : item = null;
}
