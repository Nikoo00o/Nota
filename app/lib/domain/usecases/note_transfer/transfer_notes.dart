import 'dart:async';

import 'package:app/core/utils/security_utils_extension.dart';
import 'package:app/domain/entities/client_account.dart';
import 'package:app/domain/repositories/note_transfer_repository.dart';
import 'package:app/domain/usecases/account/get_logged_in_account.dart';
import 'package:app/domain/usecases/account/save_account.dart';
import 'package:app/domain/usecases/note_transfer/inner/fetch_new_note_structure.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/services/dialog_service.dart';
import 'package:shared/core/enums/note_transfer_status.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:shared/domain/entities/note_info.dart';
import 'package:shared/domain/entities/note_update.dart';
import 'package:shared/domain/usecases/usecase.dart';

/// This updates the notes on server and client side by executing the note transfer.
/// It updates the account and the note files remotely and locally!
///
/// This can throw the exceptions of [NoteTransferRepository.startNoteTransfer], [NoteTransferRepository.uploadOrDownloadNote]
/// , [NoteTransferRepository.finishNoteTransfer], [NoteTransferRepository.renameNote] and [FetchNewNoteStructure]!
///
/// This can also throw the exceptions of [GetLoggedInAccount]!
///
/// At the end of this, [FetchNewNoteStructure] is called to create a new note structure and update the ui!
class TransferNotes extends UseCase<void, NoParams> {
  final GetLoggedInAccount getLoggedInAccount;
  final SaveAccount saveAccount;
  final NoteTransferRepository noteTransferRepository;
  final DialogService dialogService;
  final FetchNewNoteStructure fetchNewNoteStructure;

  const TransferNotes({
    required this.getLoggedInAccount,
    required this.saveAccount,
    required this.noteTransferRepository,
    required this.dialogService,
    required this.fetchNewNoteStructure,
  });

  @override
  Future<void> execute(NoParams params) async {
    final ClientAccount account = await getLoggedInAccount.call(const NoParams());
    Logger.verbose("Starting note transfer for the account $account");

    final List<NoteUpdate> noteUpdates = await noteTransferRepository.startNoteTransfer(account.noteInfoList);
    if (await _didUserCancel(noteUpdates, account)) {
      Logger.info("User cancelled note transfer");
      await noteTransferRepository.finishNoteTransfer(shouldCancel: true);
      return;
    }

    try {
      await _transferUpdates(noteUpdates);

      Logger.verbose("Finishing note transfer");
      await noteTransferRepository.finishNoteTransfer(shouldCancel: false);

      Logger.verbose("Applying the temp note data changes");
      await noteTransferRepository.replaceNotesWithTemp();

      Logger.verbose("Applying the account note info changes"); // must be after replacing, because of the id changes!
      await _applyAccountChanges(noteUpdates, account);
    } catch (e) {
      Logger.warn("Clearing temp notes, because the transfer failed $e");
      await noteTransferRepository.clearTempNotes();
      rethrow;
    }

    await saveAccount.call(const NoParams()); // always save changes to the account to the local storage at the end!
    await fetchNewNoteStructure.call(const NoParams()); // refresh note structure and ui!
    Logger.info("Transferred notes between client and server: $noteUpdates");
  }

  Future<void> _applyAccountChanges(List<NoteUpdate> updates, ClientAccount account) async {
    for (final NoteUpdate update in updates) {
      final int? newId = update.clientId != update.serverId ? update.serverId : null;
      String? newFileName;
      DateTime? newTimeStamp;

      if (update.noteTransferStatus.clientNeedsUpdate) {
        assert(update.clientId == update.serverId, "client and server id should always match on client update");
        if (update.wasFileDeleted) {
          await noteTransferRepository.deleteNote(noteId: update.clientId);
        }
        if (update.wasFileNameChanged) {
          newFileName = update.newEncFileName;
        }
        newTimeStamp = update.newLastEdited;
      }

      await _applyChange(newId, newFileName, newTimeStamp, update.clientId, account);
    }
  }

  Future<void> _applyChange(
      int? newId, String? newFileName, DateTime? newTimeStamp, int oldId, ClientAccount account) async {
    if (newId != null || newFileName != null || newTimeStamp != null) {
      Logger.verbose("Applying change with: $newId, $newFileName, $newTimeStamp to $oldId");
      final bool replaced =
          account.changeNote(noteId: oldId, newNodeId: newId, newEncFileName: newFileName, newLastEdited: newTimeStamp);
      if (replaced == false && newTimeStamp != null && newFileName != null) {
        Logger.verbose("Added new note");
        account.noteInfoList.add(NoteInfo(id: newId ?? oldId, encFileName: newFileName, lastEdited: newTimeStamp));
      } else if(newId == null) {
        Logger.warn("No note changed and also none added!");
      }

      if (newId != null) {
        await noteTransferRepository.renameNote(oldNoteId: oldId, newNoteId: newId);
      }
    }
  }

  Future<void> _transferUpdates(List<NoteUpdate> updates) async {
    for (final NoteUpdate update in updates) {
      if (update.wasFileDeleted == false) {
        Logger.verbose("Transferring update $update");
        await noteTransferRepository.uploadOrDownloadNote(noteClientId: update.clientId);
      }
    }
  }

  Future<bool> _didUserCancel(List<NoteUpdate> updates, ClientAccount account) async {
    if (_containsAServerChange(updates)) {
      final List<String> serverChanges = await _getServerChangeFileNames(updates, account);
      Logger.debug("Got the following new server changed note names: $serverChanges");

      final Completer<bool> completer = Completer<bool>();

      dialogService.show(ShowConfirmDialog(
        descriptionKey: "note.transfer.server.change.description",
        descriptionKeyParams: <String>[serverChanges.join("\n")],
        confirmButtonKey: "note.transfer.server.change.button.confirm",
        onConfirm: () => completer.complete(true),
        onCancel: () => completer.complete(false),
      ));

      final bool wasConfirmed = await completer.future;

      if (wasConfirmed == false) {
        return true;
      }
    }
    return false;
  }

  bool _containsAServerChange(List<NoteUpdate> updates) =>
      updates.where((NoteUpdate update) => update.noteTransferStatus == NoteTransferStatus.CLIENT_NEEDS_UPDATE).isNotEmpty;

  /// This returns the old client side names of the notes (if a file was renamed on server side)!
  Future<List<String>> _getServerChangeFileNames(List<NoteUpdate> updates, ClientAccount account) async {
    final List<String> serverNames = List<String>.empty(growable: true);
    final List<NoteUpdate> serverChanges =
        updates.where((NoteUpdate update) => update.noteTransferStatus == NoteTransferStatus.CLIENT_NEEDS_UPDATE).toList();

    final List<NoteInfo> affectedClientNotes = account.noteInfoList.where((NoteInfo note) {
      return serverChanges.where((NoteUpdate update) => update.clientId == note.id).isNotEmpty;
    }).toList();

    for (final NoteInfo note in affectedClientNotes) {
      final String decryptedName =
          await SecurityUtilsExtension.decryptStringAsync2(note.encFileName, account.decryptedDataKey!);
      serverNames.add(decryptedName);
    }

    return serverNames;
  }
}
