import 'dart:io';
import 'package:server/core/config/server_config.dart';
import 'package:server/data/datasources/local_data_source.dart';
import 'package:server/data/repositories/note_repository.dart';
import 'package:synchronized/synchronized.dart';

/// This should only be used by the [NoteRepository].
class NoteDataSource {
  final ServerConfig serverConfig;
  final LocalDataSource localDataSource;

  /// Used to synchronize the note counter
  final Lock _counterLock = Lock();

  NoteDataSource({required this.serverConfig, required this.localDataSource});

  /// Returns a new incremented note counter and also saves the update. This needs to be synchronized so that the counter
  /// is unique and it cant happen that 2 calls get the same counter!!!
  Future<int> getNewNoteCounter() async {
    return _counterLock.synchronized(() async {
      int noteCounter = await localDataSource.getNoteCounter();
      noteCounter += 1;
      await localDataSource.setNoteCounter(noteCounter);
      return noteCounter;
    });
  }
}
