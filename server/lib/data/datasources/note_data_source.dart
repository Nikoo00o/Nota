import 'dart:io';
import 'dart:typed_data';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:shared/core/config/shared_config.dart';
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

  /// Returns a new incremented server note counter and also saves the update. This needs to be synchronized so that the
  /// counter is unique and it cant happen that 2 calls get the same counter!!!
  ///
  /// This will always be higher than 0!
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
  /// throws a [FileException] with [ErrorCodes.FILE_NOT_FOUND] if the file does not exist!
  Future<Uint8List> loadNoteData(int noteId) async {
    return _fileLock.synchronized(() async {
      final String filePath = getFilePath(noteId, null);
      if (await FileUtils.fileExistsAsync(filePath)) {
        Logger.debug("Loaded note file $filePath");
        final Uint8List? fileContent = await FileUtils.readFileAsBytes(filePath);
        return fileContent!; // can not be null, because file must exist
      }
      Logger.error("Cannot load note file $filePath");
      throw FileException(message: ErrorCodes.FILE_NOT_FOUND, messageParams: <String>[noteId.toString()]);
    });
  }

  /// Saves the note data to a temporary file for the transfer. Creates the file if it does not exist!
  Future<void> saveTempNoteData(int noteId, String transferToken, List<int> bytes) async {
    await _fileLock.synchronized(() async {
      final String filePath = getFilePath(noteId, transferToken);
      await FileUtils.writeFileAsBytes(filePath, bytes);
      Logger.debug("Saved note file $filePath");
    });
  }

  /// For temporary transfer notes, you can also use the optional [transferToken] parameter. Otherwise leave it empty
  ///
  /// Deletes the note data file if it exists!
  Future<void> deleteNoteData(int noteId, {String? transferToken}) async {
    await _fileLock.synchronized(() async {
      final String filePath = getFilePath(noteId, transferToken);
      if (await FileUtils.fileExistsAsync(filePath)) {
        Logger.debug("Deleted note file $filePath");
        return FileUtils.deleteFile(filePath);
      } else {
        Logger.error("Cannot delete file: $filePath");
      }
    });
  }

  /// Should be called at the start of the server to cleanup remaining notes which might be left overs from a crash.
  ///
  /// You can also optionally put in the [transferToken] to only cleanup the temp notes for that transfer!
  Future<void> deleteAllTempNotes({String? transferToken}) async {
    await _fileLock.synchronized(() async {
      final Directory directory = Directory(serverConfig.noteFolder);
      await directory.list().forEach((FileSystemEntity file) {
        if (file is File && file.path.endsWith(SharedConfig.noteFileEnding(isTempNote: true))) {
          if (transferToken == null || file.path.startsWith(_transferTempBasePath(transferToken))) {
            Logger.debug("Cleaning up temporary note file: ${file.path}");
            file.deleteSync();
          }
        }
      });
    });
  }

  /// Replaces the real note data with the temporary note data of the transfer by renaming and deleting the files!
  ///
  /// throws a [FileException] with [ErrorCodes.FILE_NOT_FOUND] if the temp file does not exist!
  Future<void> replaceNoteDataWithTempData(int noteId, String transferToken) async {
    await _fileLock.synchronized(() async {
      final String tempFilePath = getFilePath(noteId, transferToken);
      final String realFilePath = getFilePath(noteId, null);
      final bool tmpFileExists = await FileUtils.fileExistsAsync(tempFilePath);

      if (tmpFileExists == false) {
        Logger.error("Cannot replace data with temp file: $tempFilePath");
        throw FileException(message: ErrorCodes.FILE_NOT_FOUND, messageParams: <String>[noteId.toString()]);
      }
      if (await FileUtils.fileExistsAsync(realFilePath)) {
        await FileUtils.deleteFileAsync(realFilePath);
      }
      await FileUtils.moveFileAsync(tempFilePath, realFilePath);
      Logger.debug("Replaced the real note $realFilePath with the temp note $tempFilePath");
    });
  }

  /// returns the file path for a real note, or a temp note
  String getFilePath(int noteId, String? transferToken) {
    final String fileEnding = SharedConfig.noteFileEnding(isTempNote: transferToken != null);
    if (transferToken != null) {
      return "${_transferTempBasePath(transferToken)}$noteId$fileEnding";
    } else {
      return "$_baseDir${Platform.pathSeparator}$noteId$fileEnding";
    }
  }

  String _transferTempBasePath(String transferToken) => "$_baseDir${Platform.pathSeparator}${transferToken}_";

  String get _baseDir => serverConfig.noteFolder;
}
