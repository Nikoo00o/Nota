import 'package:app/domain/entities/structure_folder.dart';
import 'package:shared/core/config/shared_config.dart';
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
          "directParent": directParent,
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
      return "${directParent!.path}$delimiter$name";
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
}
