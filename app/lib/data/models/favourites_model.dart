import 'package:app/domain/entities/favourites.dart';
import 'package:shared/data/models/model.dart';

class FavouritesModel extends Favourites implements Model {
  static const String JSON_FAVOURITES = "JSON_FAVOURITES";
  static const String JSON_PATH = "JSON_PATH";
  static const String JSON_ID = "JSON_ID";

  FavouritesModel({
    required super.favourites,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_FAVOURITES: favourites.map((Favourite fav) => favouriteToJson(fav)).toList(),
    };
  }

  factory FavouritesModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> favouritesDynList = json[JSON_FAVOURITES] as List<dynamic>;
    final List<Favourite> favouritesList =
        favouritesDynList.map<Favourite>((dynamic map) => favouriteFromJson(map as Map<String, dynamic>)).toList();

    return FavouritesModel(favourites: favouritesList);
  }

  static Favourite favouriteFromJson(Map<String, dynamic> map) {
    if (map.containsKey(JSON_ID)) {
      return NoteFavourite(id: map[JSON_ID] as int);
    } else if (map.containsKey(JSON_PATH)) {
      return FolderFavourite(path: map[JSON_PATH] as String);
    }
    throw UnimplementedError();
  }

  static Map<String, dynamic> favouriteToJson(Favourite favourite) {
    if (favourite is NoteFavourite) {
      return <String, dynamic>{JSON_ID: favourite.id};
    } else if (favourite is FolderFavourite) {
      return <String, dynamic>{JSON_PATH: favourite.path};
    }
    throw UnimplementedError();
  }

  factory FavouritesModel.fromFavourites(Favourites entity) {
    if (entity is FavouritesModel) {
      return entity;
    }
    return FavouritesModel(favourites: entity.favourites);
  }
}
