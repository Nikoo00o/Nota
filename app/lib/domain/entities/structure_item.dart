import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:intl/intl.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/entity.dart';

/// The base class for the structure notes and folders which are displayed in the main view of the gui!
///
/// For equality this does not use the reference to the parent folder and instead uses the [path] of the parent and the
/// top most parent name! The operator== should be used to compare if "references" are the same within a folder structure.
///
/// If you want to know if the item itself has the same values as another, then compare [StructureNote] by comparing the id
/// and [StructureFolder] by comparing the path instead!
abstract class StructureItem extends Entity {
  /// The reserved names for the "root" top level folder.
  /// Contains the translation key first and then the translation values for all languages!
  static List<String> rootFolderNames = <String>["notes.root", "root", "stammordner"];

  /// The reserved names for the "recent notes" top level folder.
  /// Contains the translation key first and then the translation values for all languages!
  static List<String> recentFolderNames = <String>["notes.recent", "recent notes", "zuletzt bearbeitet"];

  /// The reserved names for the "move notes" top level folder.
  /// Contains the translation key first and then the translation values for all languages!
  static List<String> moveFolderNames = <String>["notes.move", "select target folder", "zielordner auswählen"];

  /// The decrypted name of this item (folder, or file) without the parent path.
  ///
  /// This does not include a file extension!
  final String name;

  /// The direct parent folder of this item.
  /// This is null for top level folders and those can also not navigate to their parents!
  ///
  /// For structure notes, this is never null!
  ///
  /// The parent is not compared and also not printed in the to string method!
  final StructureFolder? directParent;

  /// If this structure item can be renamed, deleted, or moved.
  /// This is always true if the item has a parent except for the top level folders, or for the move item view!
  final bool canBeModified;

  /// The type of the note (could be something special, but also could be just a raw text file, or a folder).
  ///
  /// This should always stay the same and is never modified (so it is also not included inside of the [copyWith]
  /// methods.
  final NoteType noteType;

  StructureItem({
    required this.name,
    required this.directParent,
    required this.canBeModified,
    required this.noteType,
    required Map<String, Object?> additionalProperties,
  }) : super(<String, Object?>{
          "name": name,
          "parentPath": directParent?.path,
          "topMostParent": directParent?.topMostParent.name,
          "noteType": noteType,
          ...additionalProperties,
        });

  static String get delimiter => SharedConfig.noteStructureDelimiter;

  /// The path is platform independent and will be: "[directParent.path] + [delimiter] + [name]".
  /// Important: this will not include the root, or recent folder!!!
  ///
  /// This is equal to the decrypted file name of a note.
  ///
  /// For "root" it will only be "root" and for "recent" it will only be recent!
  String get path {
    if (directParent != null) {
      return directParent!.getPathForChildName(name);
    }
    return name;
  }

  /// Returns when this item was modified. Files store this date and folders just return the newest time stamp of the
  /// children (and if it has no children, then DateTime.fromMillisecondsSinceEpoch(0)).
  DateTime get lastModified;

  /// Returns the top most parent folder (either "root", or "recent").
  StructureFolder get topMostParent {
    if (directParent == null) {
      return this as StructureFolder; // structure notes always have a parent folder! Otherwise it is "root", or "recent"
    }
    StructureFolder root = directParent!;
    while (root.directParent != null) {
      root = root.directParent!;
    }
    return root;
  }

  bool get isRoot => rootFolderNames.contains(name.toLowerCase());

  bool get isRecent => recentFolderNames.contains(name.toLowerCase());

  bool get isMove => moveFolderNames.contains(name.toLowerCase());

  /// Returns either the [directParent] if the top most parent is "root", or otherwise it directly returns the "recent"
  /// folder and not the direct parent!
  ///
  /// This is only null for top level folders and those can also not navigate to their parents!
  StructureFolder? getParent() {
    final StructureFolder topMost = topMostParent;
    if (topMost.isRecent) {
      return topMost;
    }
    return directParent;
  }

  /// Returns if this item is a top level folder by returning if the [directParent] is null.
  bool get isTopLevel => directParent == null;

  String get lastModifiedFormatted => DateFormat("yyyy-MM-dd – HH:mm").format(lastModified);

  /// Returns if this item, or any sub folder contains the [pattern] inside of its [name]
  bool containsName(String pattern);

  /// Returns a deep copy of the [item] (recursively copy all sub folders and items).
  ///
  ///  If [changeParentOfChildren] is true, then the [directParent] of the children will be changed to this new copy!
  ///
  /// If [newDirectParent] is not null, it changes the [directParent] of the new returned item to [newDirectParent].
  ///
  /// This calls [StructureNote.copyWith] and [StructureFolder.copyWith].
  ///
  /// If [newRecursiveCanBeModified] is not null, then the [canBeModified] will be updated for all children recursively!
  static StructureItem deepCopy(
    StructureItem item, {
    StructureFolder? newDirectParent,
    required bool changeParentOfChildren,
    bool? newRecursiveCanBeModified,
  }) {
    if (item is StructureFolder) {
      return item.copyWith(
        newDirectParent: newDirectParent,
        changeParentOfChildren: changeParentOfChildren,
        newCanBeModified: newRecursiveCanBeModified,
        changeCanBeModifiedOfChildrenRecursively: newRecursiveCanBeModified != null,
      );
    } else if (item is StructureNote) {
      return item.copyWith(newDirectParent: newDirectParent, newCanBeModified: newRecursiveCanBeModified);
    }
    throw UnimplementedError();
  }

  /// This throws [ErrorCodes.INVALID_PARAMS] if the [nameToValidate] is empty, or if it contains the [delimiter].
  ///
  /// It throws [ErrorCodes.NAME_ALREADY_USED] if the [StructureItem.recentFolderNames], or
  /// [StructureItem.rootFolderNames], or [StructureItem.moveFolderNames] contain the name.
  static void throwErrorForName(String nameToValidate) {
    if (nameToValidate.isEmpty || nameToValidate.contains(StructureItem.delimiter)) {
      Logger.warn("The name $nameToValidate is empty, or it contains a ${StructureItem.delimiter}");
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    if (recentFolderNames.contains(nameToValidate.toLowerCase()) ||
        rootFolderNames.contains(nameToValidate.toLowerCase()) ||
        moveFolderNames.contains(nameToValidate.toLowerCase())) {
      Logger.warn("The name $nameToValidate is a reserved name");
      throw const ClientException(message: ErrorCodes.NAME_ALREADY_USED);
    }
  }

  /// This will return the correct translation key for root, recent and move selection.
  ///
  /// For others it will return "empty.params.1" with the name of the [structureItem] as the keyParams.
  static TranslationString getTranslationStringForStructureItem(StructureItem structureItem) {
    String translationKey = "empty.param.1";
    if (structureItem.isRecent) {
      translationKey = StructureItem.recentFolderNames.first;
    } else if (structureItem.isRoot) {
      translationKey = StructureItem.rootFolderNames.first;
    } else if (structureItem.isMove) {
      translationKey = StructureItem.moveFolderNames.first;
    } else {
      return TranslationString(translationKey, translationKeyParams: <String>[structureItem.name]);
    }
    return TranslationString(translationKey);
  }
}
