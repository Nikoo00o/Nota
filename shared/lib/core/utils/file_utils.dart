import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class FileUtils {
  /// Returns the absolute full file path for a local relative file path inside of the working directory (server, or client
  /// root)
  static String getLocalFilePath(String localPath) => "${Directory.current.path}${Platform.pathSeparator}$localPath";

  /// Read the content of the file as string.
  ///
  /// Throws an exception if the file at [path] could not be found!
  static String readFile(String path) {
    final File file = File(path);
    assert(file.existsSync(), "error, file $path does not exist");
    return File(path).readAsStringSync();
  }

  /// Write the [content] as a file at the [path] and also creates the parent directories
  static void writeFile(String path, String content) {
    final File file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(content, flush: true);
  }

  /// Returns the [bytes] of the file at the [path], or returns [null] if the file was not found!
  ///
  /// An empty file will return an empty [Uint8List]!
  static Future<Uint8List?> readFileAsBytes(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  /// Write the [bytes] as a file at the [path] and also creates the parent directories
  static Future<void> writeFileAsBytes(String path, List<int> bytes) async {
    final File file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  static bool deleteFile(String path) {
    final File file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
      return true;
    }
    return false;
  }

  static Future<bool> deleteFileAsync(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static bool fileExists(String path) => File(path).existsSync();

  static Future<bool> fileExistsAsync(String path) async {
    final File file = File(path);
    return file.exists();
  }

  /// The [oldPath] file must exist for this to work! Otherwise an exception will be thrown!
  ///
  /// This will create the parent directories for [newPath]
  static void copyFile(String oldPath, String newPath) {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    assert(oldFile.existsSync(), "error, file $oldPath does not exist");
    newFile.parent.createSync();
    oldFile.copySync(newFile.path);
  }

  /// The [oldPath] file must exist for this to work! Otherwise an exception will be thrown!
  ///
  /// This will create the parent directories for [newPath]
  static void moveFile(String oldPath, String newPath) {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    assert(oldFile.existsSync(), "error, file $oldPath does not exist");
    newFile.parent.createSync();
    newFile.parent.renameSync(newPath);
  }

  /// The [oldPath] file must exist for this to work! Otherwise an exception will be thrown!
  ///
  /// This will create the parent directories for [newPath]
  static Future<void> moveFileAsync(String oldPath, String newPath) async {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    assert(await oldFile.exists(), "error, file $oldPath does not exist");
    await newFile.parent.create();
    await oldFile.rename(newFile.path);
  }

  /// Creates the path structure with directories for the directory at the path.
  /// If the [path] points to a file, then it will only create the parent directory.
  static void createDirectory(String path) {
    final Directory directory = _getDirectoryForPath(path);
    if (directory.existsSync() == false) {
      directory.createSync(recursive: true);
    }
  }

  /// Deletes the directory with the path
  ///
  /// If the [path] points to a File, then the parent directory is deleted
  static void deleteDirectory(String path) {
    final Directory directory = _getDirectoryForPath(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  /// Returns a list of files of either the directory at [path], or the parent directory if [path] is a file
  static List<String> getFilesInDirectory(String path) {
    final Directory directory = _getDirectoryForPath(path);
    final List<FileSystemEntity> files = directory.listSync();
    return files.map((FileSystemEntity file) => file.path).toList();
  }

  /// Returns either the directory at [path], or the parent directory if [path] is a file
  static Directory _getDirectoryForPath(String path) {
    if (File(path).existsSync()) {
      return File(path).parent;
    } else {
      return Directory(path);
    }
  }
}
