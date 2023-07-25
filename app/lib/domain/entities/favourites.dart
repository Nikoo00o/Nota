import 'dart:collection';

import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/entity.dart';

/// The internal [favourites] are modified, so this is not completely immutable!
class Favourites extends Entity {
  final List<Favourite> _favourites;

  /// The list must be modifiable, so don't use a const created list!
  Favourites({
    required List<Favourite> favourites,
  })  : _favourites = favourites,
        super(<String, dynamic>{"favourites": favourites});

  void addFavourite(StructureItem item) {
    if (item is StructureFolder) {
      _favourites.add(FolderFavourite(name: item.name, path: item.path));
    } else if (item is StructureNote) {
      _favourites.add(NoteFavourite(name: item.name, id: item.id));
    }
  }

  UnmodifiableListView<Favourite> get favourites => UnmodifiableListView<Favourite>(_favourites);

  void removeFavourite(StructureItem item) {
    _favourites.removeWhere((Favourite element) => _compareItemToFavourite(element, item));
  }

  void removeFavouriteById(int id) {
    _favourites.removeWhere((Favourite element) => element is NoteFavourite && element.id == id);
  }

  void removeFavouriteByPath(String path) {
    _favourites.removeWhere((Favourite element) => element is FolderFavourite && element.path == path);
  }

  void changeFavouriteForNote(int oldId, int newId) {
    bool found = false;
    for (int i = 0; i < _favourites.length; ++i) {
      final Favourite favourite = _favourites.elementAt(i);
      if (favourite is NoteFavourite && favourite.id == oldId) {
        _favourites[i] = NoteFavourite(name: favourite.name, id: newId);
        found = true;
      }
    }
    if (!found) {
      Logger.warn("changing favourite notes did not find $oldId");
    }
  }

  bool isFavourite(StructureItem item) {
    return _favourites.where((Favourite element) => _compareItemToFavourite(element, item)).isNotEmpty;
  }

  bool isNoteFavourite(int noteId) {
    return _favourites.where((Favourite element) => element is NoteFavourite && element.id == noteId).isNotEmpty;
  }

  /// returns if [favourite] is equal to [item]
  bool _compareItemToFavourite(Favourite favourite, StructureItem item) {
    if (favourite is FolderFavourite && item is StructureFolder) {
      return favourite.path == item.path;
    }
    if (favourite is NoteFavourite && item is StructureNote) {
      return favourite.id == item.id;
    }
    return false;
  }
}

sealed class Favourite extends Entity {
  final String name;

  const Favourite(super.properties, {required this.name});
}

final class FolderFavourite extends Favourite {
  final String path;

  FolderFavourite({
    required this.path,
    required super.name,
  }) : super(<String, dynamic>{
          "name": name,
          "path": path,
        });
}

final class NoteFavourite extends Favourite {
  final int id;

  NoteFavourite({
    required this.id,
    required super.name,
  }) : super(<String, dynamic>{
          "name": name,
          "id": id,
        });
}
