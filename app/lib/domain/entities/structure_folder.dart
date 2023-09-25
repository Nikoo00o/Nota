import 'package:app/core/enums/note_sorting.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// A folder is uniquely identified by its full [path]!
///
/// Here the [noteType] is always [NoteType.FOLDER]
class StructureFolder extends StructureItem {
  /// The folders and files within this folder.
  ///
  /// This will not be used for comparison and can be modified!
  late final List<StructureItem> _children;

  /// The sorting of the children of this folder
  final NoteSorting sorting;

  /// This controls the name comparison of children and is set by the app config (so this is not used inside of this
  /// object)
  final bool compareCaseSensitive;

  /// The [children] list will be deep copied by calling [StructureItem.deepCopy] and it will be sorted.
  ///
  /// If [changeParentOfChildren] is [true], then the individual children elements will also have their [directParent]
  /// changed to [this]!!!
  ///
  /// If [changeCanBeModifiedOfChildrenRecursively] is true then all copies of the [children] will get the updated value of
  /// [canBeModified].
  factory StructureFolder({
    required String name,
    required StructureFolder? directParent,
    required bool canBeModified,
    required List<StructureItem> children,
    required NoteSorting sorting,
    required bool changeParentOfChildren,
    bool changeCanBeModifiedOfChildrenRecursively = false,
    required bool compareCaseSensitive,
  }) {
    // note type is always FOLDER!
    final StructureFolder folder = StructureFolder._internal(
      name: name,
      directParent: directParent,
      canBeModified: canBeModified,
      noteType: NoteType.FOLDER,
      children: List<StructureItem>.empty(growable: true),
      sorting: sorting,
      compareCaseSensitive: compareCaseSensitive,
    );

    for (final StructureItem child in children) {
      folder._children.add(StructureItem.deepCopy(
        child,
        newDirectParent: changeParentOfChildren ? folder : null,
        changeParentOfChildren: changeParentOfChildren,
        newRecursiveCanBeModified: changeCanBeModifiedOfChildrenRecursively ? canBeModified : null,
      ));
    }

    return folder;
  }

  StructureFolder._internal({
    required super.name,
    required super.directParent,
    required super.canBeModified,
    required super.noteType,
    required List<StructureItem> children,
    required this.sorting,
    required this.compareCaseSensitive,
  })  : _children = children,
        super(additionalProperties: <String, Object?>{
          "children": children,
          "sorting": sorting,
        }) {
    sortChildren();
  }

  /// Adds a deep copy of the [child] with the [directParent] set to [this].
  ///
  /// If [sortAfterwards] is true, then this will sort the children afterwards.
  ///
  /// This also returns the reference to the new deep copied child which is stored inside of the children!
  StructureItem addChild(StructureItem child, {bool sortAfterwards = true}) {
    final StructureItem newChild = StructureItem.deepCopy(child, newDirectParent: this, changeParentOfChildren: true);
    _children.add(newChild);
    if (sortAfterwards) {
      sortChildren();
    }
    return newChild;
  }

  /// Removes the child at the [position].
  /// Can throw [ErrorCodes.INVALID_PARAMS].
  void removeChild(int position) {
    if (position >= _children.length) {
      Logger.error("$position was too high");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children.removeAt(position);
  }

  /// Removes the own [oldChild] reference of the children list.
  /// Can throw [ErrorCodes.INVALID_PARAMS] if it was not found.
  void removeChildRef(StructureItem oldChild) {
    final bool removed = _children.remove(oldChild);
    if (removed == false) {
      Logger.error("$oldChild was not found");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  /// Replaces the child at the [position] with a deep copy of [newChild] with the [directParent] set to [this].
  /// Can throw [ErrorCodes.INVALID_PARAMS] and sorts the children.
  void changeChild(int position, StructureItem newChild) {
    if (position >= _children.length) {
      Logger.error("$position was too high");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    _children[position] = StructureItem.deepCopy(newChild, newDirectParent: this, changeParentOfChildren: true);
    sortChildren();
  }

  /// Replaces the own children references with the [newChildren] without changing the parent, or copying them!
  /// Also sorts the children.
  void replaceChildren(List<StructureItem> newChildren) {
    _children.clear();
    for (final StructureItem child in newChildren) {
      _children.add(child);
    }
    sortChildren();
  }

  /// Replaces the own [oldChild] reference with [newChild] without changing the parent, or copying them!
  /// Also sorts the children and returns the [newChild].
  /// Can throw [ErrorCodes.INVALID_PARAMS] if the [oldChild] was not found.
  StructureItem replaceChildRef(StructureItem oldChild, StructureItem newChild) {
    for (int i = 0; i < _children.length; ++i) {
      if (_children[i] == oldChild) {
        _children[i] = newChild;
        sortChildren();
        return newChild;
      }
    }
    Logger.error("$oldChild was not found");
    throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
  }

  /// Returns a reference to the element at the [position] of the [_children].
  /// Can throw [ErrorCodes.INVALID_PARAMS].
  StructureItem getChild(int position) {
    if (position >= _children.length) {
      Logger.error("$position was too high");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    return _children.elementAt(position);
  }

  /// Returns a reference to the children note that matches the [noteId], or null if none was found (recursively)
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

  /// Returns a reference, or deep copy of the children folder recursively for which its full path equals [path], or
  /// null if none was found!
  StructureFolder? getFolderByPath(String path, {required bool deepCopy}) {
    if (path == this.path) {
      if (deepCopy) {
        return copyWith(changeParentOfChildren: true);
      } else {
        return this;
      }
    }
    for (final StructureItem child in _children) {
      if (child is StructureFolder) {
        if (path == child.path) {
          return child;
        } else if (path.startsWith("${child.path}${StructureItem.delimiter}")) {
          return child.getFolderByPath(path, deepCopy: deepCopy);
        }
      }
    }
    return null;
  }

  /// Returns a reference, or deep copy of the direct folder children that has the same [name], or null if none was found!
  StructureFolder? getDirectFolderByName(String name, {required bool deepCopy}) {
    if (name == this.name) {
      if (deepCopy) {
        return copyWith(changeParentOfChildren: true);
      } else {
        return this;
      }
    }
    for (final StructureItem child in _children) {
      if (child is StructureFolder && child.name == name) {
        return child;
      }
    }
    return null;
  }

  /// Returns all children note references of this folder recursively as a new list.
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

  /// Removes all notes recursively from this folder and all sub folders.
  void removeAllNotes() {
    _children.removeWhere((StructureItem item) => item is StructureNote);
    for (final StructureItem child in _children) {
      (child as StructureFolder).removeAllNotes();
    }
  }

  /// If [recursive] is true, all sub folders will also be sorted!
  void sortChildren({bool recursive = false}) {
    if (sorting == NoteSorting.BY_NAME) {
      if (compareCaseSensitive) {
        _children.sort(_sortByNameCaseSensitive);
      } else {
        _children.sort(_sortByNameCaseInSensitive);
      }
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

  /// Returns "[path] + [delimiter] + [name]" for non top level folders. Otherwise it just returns the [name].
  String getPathForChildName(String name) {
    if (isTopLevel == false) {
      return "$path${StructureItem.delimiter}$name";
    }
    return name;
  }

  int get amountOfChildren => _children.length;

  /// Compares 2 structure items in alphabetical order
  static int _sortByNameCaseSensitive(StructureItem first, StructureItem second) => first.name.compareTo(second.name);

  /// Compares 2 structure items in alphabetical order in lowercase
  static int _sortByNameCaseInSensitive(StructureItem first, StructureItem second) =>
      first.name.toLowerCase().compareTo(second.name.toLowerCase());

  /// Compares 2 structure items by the newest modified time stamp first in descending order
  static int _sortByDate(StructureItem first, StructureItem second) =>
      second.lastModified.compareTo(first.lastModified);

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

  /// This makes a deep copy of this, so every sub folder and note file will be copied!
  ///
  /// If [changeParentOfChildren] is true, then the [directParent] of the children will be changed to this new copy!
  /// Most of the times when working with the folders, this will be true, but when getting it for the guy, or when working
  /// with the top level folder "recent", then it will be false (because for recent it would change the parent of the items)!
  ///
  /// The [newChildren], or [_children] will be copied to a new list and each folder, or note file will be deep copied!
  ///
  /// This also calls [StructureItem.deepCopy].
  ///
  /// This can throw an [ErrorCodes.INVALID_PARAMS] when [isRecent] and [changeParentOfChildren] is true!
  ///
  /// If [changeCanBeModifiedOfChildrenRecursively] is true and [newCanBeModified] is not null, then all copies of the
  /// children will get the updated value.
  StructureFolder copyWith({
    String? newName,
    StructureFolder? newDirectParent,
    bool? newCanBeModified,
    List<StructureItem>? newChildren,
    NoteSorting? newSorting,
    required bool changeParentOfChildren,
    bool changeCanBeModifiedOfChildrenRecursively = false,
  }) {
    if (isRecent && changeParentOfChildren) {
      Logger.error("CopyWith called on recent with changeParentOfChildren enabled:\ $this");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }
    return StructureFolder(
      name: newName ?? name,
      directParent: newDirectParent ?? directParent,
      canBeModified: newCanBeModified ?? canBeModified,
      children: newChildren ?? _children,
      sorting: newSorting ?? sorting,
      changeParentOfChildren: changeParentOfChildren,
      changeCanBeModifiedOfChildrenRecursively: changeCanBeModifiedOfChildrenRecursively && newCanBeModified != null,
      compareCaseSensitive: compareCaseSensitive,
    );
  }

  @override
  bool containsName(String pattern, {required bool caseSensitive}) {
    if (caseSensitive) {
      if (name.contains(pattern)) {
        return true;
      }
    } else {
      if (name.toLowerCase().contains(pattern.toLowerCase())) {
        return true;
      }
    }
    for (final StructureItem child in _children) {
      if (child.containsName(pattern, caseSensitive: caseSensitive)) {
        return true;
      }
    }
    return false;
  }

  @override
  String shortString() => "Folder $name with {${_children.map((StructureItem e) => "${e.name}, ").toList()}}";

  /// returns the full paths of all notes inside of this folder
  List<String> getAllNotePaths() => getAllNotes().map((StructureNote note) => note.path).toList();
}
