import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_note.dart';
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/domain/entities/entity.dart';

/// The base class for the structure notes and folders which are displayed in the main view of the gui!
abstract class StructureItem extends Entity {
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

  StructureItem({
    required this.name,
    required this.directParent,
    required this.canBeModified,
    required Map<String, Object?> additionalProperties,
  }) : super(<String, Object?>{
          "name": name,
          "directParentName": directParent?.name,
          ...additionalProperties,
        });

  static String get delimiter => SharedConfig.noteStructureDelimiter;

  /// The path is platform independent and will be: "[directParent.path] + [delimiter] + [name]".
  ///
  /// Important: this will not include the root, or recent folder!!!
  ///
  /// This is equal to the decrypted file name of a note.
  String get path {
    if (directParent != null && directParent!.isRoot == false && directParent!.isRecent == false) {
      return directParent!.getPathForChildName(name);
    }
    return name;
  }

  /// Returns when this item was modified. Files store this date and folders just return the newest time stamp of the
  /// children.
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

  /// Returns either the [directParent] if the top most parent is "root", or otherwise it directly returns the "recent"
  /// folder and not the direct parent!
  StructureFolder? getParent() {
    final StructureFolder topMost = topMostParent;
    if (topMost.isRecent) {
      return topMost;
    }
    return directParent;
  }

  /// Returns a deep copy of the [item] (recursively copy all sub folders and items).
  ///
  ///  If [changeParentOfChildren] is true, then the [directParent] of the children will be changed to this new copy!
  ///
  /// If [newDirectParent] is not null, it changes the [directParent] of the new returned item to [newDirectParent].
  ///
  /// This calls [StructureNote.copyWith] and [StructureFolder.copyWith].
  static StructureItem deepCopy(StructureItem item,
      {StructureFolder? newDirectParent, required bool changeParentOfChildren}) {
    if (item is StructureFolder) {
      return item.copyWith(newDirectParent: newDirectParent, changeParentOfChildren: changeParentOfChildren);
    } else if (item is StructureNote) {
      return item.copyWith(newDirectParent: newDirectParent);
    }
    throw UnimplementedError();
  }

  /// This throws [ErrorCodes.INVALID_PARAMS] if the [nameToValidate] is empty, or if it contains the [delimiter].
  ///
  /// It throws [ErrorCodes.NAME_ALREADY_USED] if the [StructureFolder.recentFolderNames], or
  /// [StructureFolder.rootFolderNames] contain  the name.
  static void throwErrorForName(String nameToValidate) {
    if (nameToValidate.isEmpty || nameToValidate.contains(StructureItem.delimiter)) {
      throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
    }

    if (StructureFolder.recentFolderNames.contains(nameToValidate) ||
        StructureFolder.rootFolderNames.contains(nameToValidate)) {
      throw const ClientException(message: ErrorCodes.NAME_ALREADY_USED);
    }
  }
}
