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
      final StructureItem item = folder._children[i];
      if (item is StructureFolder) {
        folder._children[i] = item.copyWith(newDirectParent: folder);
      } else if (item is StructureNote) {
        folder._children[i] = item.copyWith(newDirectParent: folder);
      }
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
    _sortChildren();
  }

  /// Sorts the children.
  void addChild(StructureItem child) {
    _children.add(child);
    _sortChildren();
  }

  /// Can throw [ErrorCodes.INVALID_PARAMS] and sorts the children.
  void removeChild(int position) {
    if (position >= _children.length) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children.removeAt(position);
    _sortChildren();
  }

  /// Can throw [ErrorCodes.INVALID_PARAMS] and sorts the children.
  void changeChild(int position, StructureItem newChild) {
    if (position >= _children.length) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children[position] = newChild;
    _sortChildren();
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

  /// Returns the children folder that matches the [path], or null if none was found
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

  void _sortChildren() {
    if (sorting == NoteSorting.BY_NAME) {
      _children.sort(_sortByName);
    } else if (sorting == NoteSorting.BY_DATE) {
      _children.sort(_sortByDate);
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
