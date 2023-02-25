import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';

class StructureFolder extends StructureItem {
  /// The reserved names for the "root" top level folder.
  /// Contains the translation key first and then the translation values for all languages!
  static List<String> rootFolderNames = <String>["notes.root", "Root", "Stammordner"];

  /// The reserved names for the "recent notes" top level folder.
  /// Contains the translation key first and then the translation values for all languages!
  static List<String> recentFolderNames = <String>["notes.recent", "Recent Notes", "Zuletzt Bearbeitet"];

  /// The folders and files within this folder.
  ///
  /// This will not be used for comparison and can be modified!
  late final List<StructureItem> _children;

  /// The sorting of the children of this folder
  final NoteSorting sorting;

  /// The [children] will be copied and it will be sorted and this will also copy the children and set the [directParent] of
  /// them!
  factory StructureFolder({
    required String name,
    required StructureFolder? directParent,
    required bool canBeModified,
    required List<StructureItem> children,
    required NoteSorting sorting,
  }) {
    final StructureFolder folder = StructureFolder._internal(
      name: name,
      directParent: directParent,
      canBeModified: canBeModified,
      children: List<StructureItem>.of(children),
      sorting: sorting,
    );

    for (int i = 0; i < folder._children.length; ++i) {
      folder._children[i] = StructureItem.changeParent(folder._children[i], folder);
    }

    return folder;
  }

  StructureFolder._internal({
    required super.name,
    required super.directParent,
    required super.canBeModified,
    required List<StructureItem> children,
    required this.sorting,
  })  : _children = children,
        super(additionalProperties: <String, Object?>{
          "children": children,
          "sorting": sorting,
        }) {
    sortChildren();
  }

  /// Adds a copy of the [child] with the [directParent] set to [this].
  ///
  /// If [sortAfterwards] is true, then this will sort the children afterwards.
  void addChild(StructureItem child, {bool sortAfterwards = true}) {
    _children.add(StructureItem.changeParent(child, this));
    if (sortAfterwards) {
      sortChildren();
    }
  }

  /// Removes the child at the [position].
  /// Can throw [ErrorCodes.INVALID_PARAMS] and sorts the children.
  void removeChild(int position) {
    if (position >= _children.length) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children.removeAt(position);
    sortChildren();
  }

  /// Replaces the child at the [position] with a copy of [newChild] with the [directParent] set to [this].
  /// Can throw [ErrorCodes.INVALID_PARAMS] and sorts the children.
  void changeChild(int position, StructureItem newChild) {
    if (position >= _children.length) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children[position] = StructureItem.changeParent(newChild, this);
    sortChildren();
  }

  /// Can throw [ErrorCodes.INVALID_PARAMS].
  StructureItem getChild(int position) {
    if (position >= _children.length) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    return _children.elementAt(position);
  }

  /// Returns the children note that matches the [noteId], or null if none was found (recursively)
  StructureNote? getNoteById(int noteId) {
    for (final StructureItem child in _children) {
      if (child is StructureFolder) {
        final StructureNote? childNote = child.getNoteById(noteId);
        if (childNote != null) {
          return childNote;
        }
      } else if (child is StructureNote && child.id == noteId) {
        return child;
      }
    }
    return null;
  }

  /// Returns the children folder recursively for which its full path starts with [path], or null if none was found
  StructureFolder? getFolderByPath(String path) {
    if (path == this.path) {
      return this;
    }
    for (final StructureItem child in _children) {
      if (child is StructureFolder && path.startsWith(child.path)) {
        return child.getFolderByPath(path);
      }
    }
    return null;
  }

  /// Returns the direct folder children that has the same [name], or null if none was found!
  StructureFolder? getDirectFolderByName(String name) {
    if (name == this.name) {
      return this;
    }
    for (final StructureItem child in _children) {
      if (child is StructureFolder && child.name == name) {
        return child;
      }
    }
    return null;
  }

  /// Returns all children notes of this folder recursively as a new list.
  List<StructureNote> getAllNotes() {
    final List<StructureNote> notes = List<StructureNote>.empty(growable: true);
    for (final StructureItem child in _children) {
      if (child is StructureFolder) {
        notes.addAll(child.getAllNotes());
      } else if (child is StructureNote) {
        notes.add(child);
      }
    }
    return notes;
  }

  /// If [recursive] is true, all sub folders will also be sorted!
  void sortChildren({bool recursive = false}) {
    if (sorting == NoteSorting.BY_NAME) {
      _children.sort(_sortByName);
    } else if (sorting == NoteSorting.BY_DATE) {
      _children.sort(_sortByDate);
    }
    if (recursive) {
      for (final StructureItem child in _children) {
        if (child is StructureFolder) {
          child.sortChildren(recursive: true);
        }
      }
    }
  }

  int get amountOfChildren => _children.length;

  bool get isRoot => rootFolderNames.contains(name);

  bool get isRecent => recentFolderNames.contains(name);

  /// Compares 2 structure items in alphabetical order
  static int _sortByName(StructureItem first, StructureItem second) =>
      first.name.toLowerCase().compareTo(second.name.toLowerCase());

  /// Compares 2 structure items by the newest modified time stamp first in descending order
  static int _sortByDate(StructureItem first, StructureItem second) => second.lastModified.compareTo(first.lastModified);

  @override
  DateTime get lastModified {
    DateTime newest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final StructureItem child in _children) {
      final DateTime childModified = child.lastModified;
      if (childModified.isAfter(newest)) {
        newest = childModified;
      }
    }
    return newest;
  }

  StructureFolder copyWith({
    String? newName,
    StructureFolder? newDirectParent,
    bool? newCanBeModified,
    List<StructureItem>? newChildren,
    NoteSorting? newSorting,
  }) {
    return StructureFolder(
      name: newName ?? name,
      directParent: newDirectParent ?? directParent,
      canBeModified: newCanBeModified ?? canBeModified,
      children: newChildren ?? _children,
      sorting: newSorting ?? sorting,
    );
  }
}
