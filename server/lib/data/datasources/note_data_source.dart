import 'dart:io';
import 'dart:typed_data';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';
import 'package:synchronized/synchronized.dart';

/// This should only be used by the [NoteRepository].
class NoteDataSource {
  final ServerConfig serverConfig;
  final LocalDataSource localDataSource;

  /// Used to synchronize the note counter
  final Lock _counterLock = Lock();

  /// Used to synchronize file access
  final Lock _fileLock = Lock();

  NoteDataSource({required this.serverConfig, required this.localDataSource});

  /// Must be called first in the main function to initialize the notes folder.
  ///
  /// Also calls [deleteAllTempNotes].
  Future<void> init() async {
    FileUtils.createDirectory(serverConfig.noteFolder);
    await deleteAllTempNotes();
  }

  /// Returns a new incremented note counter and also saves the update. This needs to be synchronized so that the counter
  /// is unique and it cant happen that 2 calls get the same counter!!!
  Future<int> getNewNoteCounter() async {
    return _counterLock.synchronized(() async {
      int noteCounter = await localDataSource.getNoteCounter();
      noteCounter += 1;
      await localDataSource.setNoteCounter(noteCounter);
      Logger.debug("Returned new server note counter $noteCounter");
      return noteCounter;
    });
  }

  /// Reads from the real note file of the account.
  ///
  /// throws a [ServerException] with [ErrorCodes.FILE_NOT_FOUND] if the file does not exist!
  Future<Uint8List> loadNoteData(int noteId) async {
    return _fileLock.synchronized(() async {
      final String filePath = _getFilePath(noteId, null);
      if (File(filePath).existsSync()) {
        Logger.debug("Loaded note file $filePath");
        return File(filePath).readAsBytes();
      }
      Logger.error("Cannot load note file $filePath");
      throw const ServerException(message: ErrorCodes.FILE_NOT_FOUND);
    });
  }

  /// Saves the note data to a temporary file for the transfer. Creates the file if it does not exist!
  Future<void> saveTempNoteData(int noteId, String transferToken, List<int> bytes) async {
    await _fileLock.synchronized(() async {
      final String filePath = _getFilePath(noteId, transferToken);
      await File(filePath).writeAsBytes(bytes, flush: true);
      Logger.debug("Saved note file $filePath");
    });
  }

  /// For temporary transfer notes, you can also use the optional [transferToken] parameter. Otherwise leave it empty
  ///
  /// Deletes the note data file if it exists!
  Future<void> deleteNoteData(int noteId, {String? transferToken}) async {
    await _fileLock.synchronized(() async {
      final String filePath = _getFilePath(noteId, transferToken);
      if (File(filePath).existsSync()) {
        Logger.debug("Deleted note file $filePath");
        return File(filePath).delete();
      } else {
        Logger.error("Cannot delete file: $filePath");
      }
    });
  }

  /// Should be called at the start of the server to cleanup remaining notes which might be left overs from a crash
  Future<void> deleteAllTempNotes() async {
    await _fileLock.synchronized(() async {
      final Directory directory = Directory(serverConfig.noteFolder);
      await directory.list().forEach((FileSystemEntity file) {
        if (file is File && file.path.endsWith(".temp")) {
          Logger.debug("Cleaning up temporary note file: ${file.path}");
          file.deleteSync();
        }
      });
    });
  }

  /// Replaces the real note data with the temporary note data of the transaction by renaming and deleting the files!
  ///
  /// throws a [ServerException] with [ErrorCodes.FILE_NOT_FOUND] if the temp file does not exist!
  Future<void> replaceNoteDataWithTempData(int noteId, String transferToken) async {
    await _fileLock.synchronized(() async {
      final String tempFilePath = _getFilePath(noteId, transferToken);
      final String realFilePath = _getFilePath(noteId, null);
      if (File(tempFilePath).existsSync() == false) {
        Logger.error("Cannot replace data with temp file: $tempFilePath");
        throw const ServerException(message: ErrorCodes.FILE_NOT_FOUND);
      }
      if (File(realFilePath).existsSync()) {
        await File(realFilePath).delete();
      }
      await File(tempFilePath).rename(realFilePath);
      Logger.debug("Replaced the real note $realFilePath with the temp note $tempFilePath");
    });
  }

  String _getFilePath(int noteId, String? transferToken) {
    final String baseDir = "${serverConfig.noteFolder}${Platform.pathSeparator}";
    final String fileEnding = transferToken != null ? ".temp" : ".note";
    if (transferToken != null) {
      return "$baseDir${transferToken}_$noteId$fileEnding";
    } else {
      return "$baseDir$noteId$fileEnding";
    }
  }
}
