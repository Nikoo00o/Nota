import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/entities/translation_string.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:shared/domain/entities/entity.dart';

/// This is used to send streamed copied updates of the [currentItem] and [topLevelFolders] to the ui.
///
/// This is used in [GetStructureUpdatesStream].
class StructureUpdateBatch extends Entity {
  final StructureItem currentItem;

  /// The last folder will always be the move folder and it should be ignored in the ui!!!
  final Map<TranslationString, StructureFolder> topLevelFolders;

  StructureUpdateBatch({
    required this.currentItem,
    required this.topLevelFolders,
  }) : super(<String, Object?>{
          "currentItem": currentItem,
          "topLevelFolders": topLevelFolders,
        });

  /// Returns the [topLevelFolders] that should be used for the ui and does not include the move selection folder!
  Map<TranslationString, StructureFolder> get menuItems {
    final Map<TranslationString, StructureFolder> copy = Map<TranslationString, StructureFolder>.of(topLevelFolders);
    copy.remove(TranslationString(StructureItem.moveFolderNames.first));
    return copy;
  }
}
