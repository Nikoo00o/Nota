import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:app/domain/usecases/favourites/is_favourite.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class UpdateFavourite extends UseCase<void, UpdateFavouriteParams> {
  final AppSettingsRepository appSettingsRepository;
  final IsFavourite isFavourite;

  const UpdateFavourite({
    required this.appSettingsRepository,
    required this.isFavourite,
  });

  @override
  Future<void> execute(UpdateFavouriteParams params) async {
    if (await isFavourite(IsFavouriteParams.fromNoteId(params.fromId))) {
      final Favourites favourites = await appSettingsRepository.getFavourites();
      favourites.changeFavouriteForNote(params.fromId, params.toId);
      Logger.debug("updated favourite note from ${params.fromId} to ${params.toId}");
      await appSettingsRepository.setFavourites(favourites);
    }
  }
}

class UpdateFavouriteParams {
  /// The affected structure note
  final int fromId;
  final int toId;

  UpdateFavouriteParams({
    required this.fromId,
    required this.toId,
  });
}
