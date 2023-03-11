import 'package:app/domain/entities/structure_folder.dart';
import 'package:app/domain/entities/structure_item.dart';
import 'package:app/domain/usecases/note_structure/navigation/get_structure_updates_stream.dart';
import 'package:shared/domain/entities/entity.dart';

/// This is used to send streamed copied updates of the [currentItem] and [topLevelFolders] to the ui.
///
/// This is used in [GetStructureUpdatesStream].
class StructureUpdateBatch extends Entity {
  final StructureItem? currentItem;
  final List<StructureFolder?> topLevelFolders;

  StructureUpdateBatch({
    required this.currentItem,
    required this.topLevelFolders,
  }) : super(<String, Object?>{
          "currentItem": currentItem,
          "topLevelFolders": topLevelFolders,
        });
}
