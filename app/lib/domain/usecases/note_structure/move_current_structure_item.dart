import 'package:app/domain/usecases/note_structure/inner/get_original_structure_item.dart';
import 'package:app/domain/usecases/note_structure/inner/update_note_structure.dart';
import 'package:app/domain/usecases/note_transfer/inner/store_note_encrypted.dart';
import 'package:shared/domain/usecases/usecase.dart';

// folders may not have the same name and parent!

// also check ismodifiable

// the new target parent folder may be empty if this item should be moved into the root directory


class MoveCurrentStructureItem extends UseCase<void, NoParams> {
    final GetOriginalStructureItem getOriginalStructureItem;
    final UpdateNoteStructure updateNoteStructure;
    final StoreNoteEncrypted storeNoteEncrypted;

    const MoveCurrentStructureItem({
        required this.getOriginalStructureItem,
        required this.updateNoteStructure,
        required this.storeNoteEncrypted,
    });

    @override
    Future<void> execute(NoParams params) async {

    }
}