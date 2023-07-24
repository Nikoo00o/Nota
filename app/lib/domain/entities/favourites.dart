import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/entity.dart';

/// The internal [favourites] are modified, so this is not completely immutable!
class Favourites extends Entity {
  @protected
  final List<Favourite> favourites;

  Favourites({
    required this.favourites,
  }) : super(<String, dynamic>{"favourites": favourites});

  void addFavourite(StructureItem item) {
    if (item is StructureFolder) {
      favourites.add(FolderFavourite(path: item.path));
    } else if (item is StructureNote) {
      favourites.add(NoteFavourite(id: item.id));
    }
  }

  void removeFavourite(StructureItem item) {
    if (item is StructureFolder) {
      favourites.removeWhere((Favourite element) => _compareItemToFavourite(element, item));
    } else if (item is StructureNote) {
      favourites.removeWhere((Favourite element) => _compareItemToFavourite(element, item));
    }
  }

  void changeFavouriteForNote(int oldId, int newId) {
    bool found = false;
    for (int i = 0; i < favourites.length; ++i) {
      final Favourite favourite = favourites.elementAt(i);
      if (favourite is NoteFavourite && favourite.id == oldId) {
        favourites[i] = NoteFavourite(id: newId);
        found = true;
      }
    }
    if (!found) {
      Logger.warn("changing favourite notes did not find $oldId");
    }
  }

  bool isFavourite(StructureItem item) {
    if (item is StructureFolder) {
      return favourites.where((Favourite element) => _compareItemToFavourite(element, item)).isNotEmpty;
    } else if (item is StructureNote) {
      return favourites.where((Favourite element) => _compareItemToFavourite(element, item)).isNotEmpty;
    }
    return false;
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
  const Favourite(super.properties);
}

final class FolderFavourite extends Favourite {
  final String path;

  FolderFavourite({
    required this.path,
  }) : super(<String, dynamic>{"path": path});
}

final class NoteFavourite extends Favourite {
  final int id;

  NoteFavourite({
    required this.id,
  }) : super(<String, dynamic>{"id": id});
}
