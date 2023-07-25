import 'package:app/domain/entities/favourites.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/repositories/app_settings_repository.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/usecases/usecase.dart';

class ChangeFavourite extends UseCase<void, ChangeFavouriteParams> {
  final AppSettingsRepository appSettingsRepository;

  const ChangeFavourite({
    required this.appSettingsRepository,
  });

  @override
  Future<void> execute(ChangeFavouriteParams params) async {
    final Favourites favourites = await appSettingsRepository.getFavourites();
    if (params.isFavourite) {
      favourites.addFavourite(params.item);
      Logger.info("added ${params.item.path} to favourites");
    } else {
      favourites.removeFavourite(params.item);
      Logger.info("removed ${params.item.path} from favourites");
    }
    await appSettingsRepository.setFavourites(favourites);
  }
}

class ChangeFavouriteParams {
  /// [true] if the item should be part of the favourites and [false] if it should not be.
  final bool isFavourite;

  /// The affected structure item
  final StructureItem item;

  ChangeFavouriteParams({
    required this.isFavourite,
    required this.item,
  });
}
