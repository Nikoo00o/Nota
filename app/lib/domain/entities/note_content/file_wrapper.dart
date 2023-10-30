part of "note_content.dart";

/// A raw text note with the type [NoteType.FILE_WRAPPER]. For loading, use [NoteContent.loadFile] and for saving use
/// [NoteContent.saveFile].
///
/// For this the [text] returns the file bytes
final class NoteContentFileWrapper extends NoteContent {
  /// part of the header 4 bytes to store content size
  static const int CONTENT_SIZE_BYTES = 4;

  static const int EXTERNAL_FILE_SIZE_BYTES = 4;

  static const int FILE_LAST_MODIFIED_BYTES = 8; // 64 bit

  /// last 4 bytes of the fixed header size to store path size
  static const int PATH_SIZE_BYTES = 4;

  /// a maximum of 4 gb content bytes is supported inside of file wrappers
  static const int MAX_CONTENT_BYTES = 4000000000;

  /// the current version for when writing file wrapper files (used for migration)
  static const int FILE_WRAPPER_VERSION = 1;

  /// should be the same as [headerSize] and contain all static attributes
  static int get staticHeaderSize =>
      NoteContent.baseNoteContentHeaderSize +
      CONTENT_SIZE_BYTES +
      EXTERNAL_FILE_SIZE_BYTES +
      FILE_LAST_MODIFIED_BYTES +
      PATH_SIZE_BYTES;

  /// Internally used to initialize the bytes (by copying the reference) and also the header fields!
  /// This initializes the [textSize] and the [text] part of the [bytes] itself by copying over the parts of
  /// [decryptedContent]
  ///
  /// The [combinedBytes] must be created to be large enough to fit the header fields in addition to any other content
  ///
  /// This also calls [NoteContent._save] and is called by [NoteContentFileWrapper._saveFile]
  NoteContentFileWrapper._save({
    required Uint8List combinedBytes,
    required int headerSize,
    required int pathSize,
    required int contentSize,
    required List<int> decryptedContent,
    required int externalFileSize,
    required int fileLastModified,
    required List<int> pathBytes,
  }) : super._save(combinedBytes, headerSize, FILE_WRAPPER_VERSION) {
    int offset = NoteContent.baseNoteContentHeaderSize;
    _data.setUint32(offset, contentSize, Endian.big);
    offset += CONTENT_SIZE_BYTES;
    _data.setUint32(offset, externalFileSize, Endian.big);
    offset += EXTERNAL_FILE_SIZE_BYTES;
    _data.setUint64(offset, fileLastModified, Endian.big);
    offset += FILE_LAST_MODIFIED_BYTES;
    _data.setUint32(offset, pathSize, Endian.big);
    _checkRawTextHeaderFields();
    for (int i = 0; i < pathBytes.length; ++i) {
      combinedBytes[i + headerSize] = pathBytes[i]; // headerSize is the offset for the path part
    }
    for (int i = 0; i < decryptedContent.length; ++i) {
      combinedBytes[i + headerSize + pathSize] = decryptedContent[i]; // headerSize and pathsize here
    }
  }

  void _checkRawTextHeaderFields() {
    if (contentSize >= MAX_CONTENT_BYTES) {
      Logger.error("content size $contentSize, was bigger, or equal to ${MAX_CONTENT_BYTES / 1000000000} GB");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    final int combined = headerSize + pathSize + contentSize;
    if (_bytes.length < combined) {
      Logger.error("bytes length ${_bytes.length} is smaller than header size and content size $combined");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  /// Creates a new [NoteContentFileWrapper] for [NoteType.FILE_WRAPPER] for the [decryptedContent] of the extern
  /// file (the bytes itself).
  /// This will create the [_bytes] list with the header information and copies the [decryptedContent] into it.
  /// The [params] contains additional data to be saved into the [_bytes]
  factory NoteContentFileWrapper._saveFile({
    required List<int> decryptedContent,
    required FileWrapperParams params,
  }) {
    final int headerSize = staticHeaderSize; // full static header size
    final Uint8List pathBytes = Uint8List.fromList(utf8.encode(params.fileInfo.path));
    final int pathSize = pathBytes.length;
    final int contentSize = decryptedContent.length;
    final Uint8List combinedBytes = Uint8List(headerSize + pathSize + contentSize);
    return NoteContentFileWrapper._save(
      combinedBytes: combinedBytes,
      headerSize: headerSize,
      pathSize: pathSize,
      contentSize: contentSize,
      decryptedContent: decryptedContent,
      externalFileSize: params.fileInfo.size,
      fileLastModified: params.fileInfo.lastModified.millisecondsSinceEpoch,
      pathBytes: pathBytes,
    );
  }

  /// Used internally by [NoteContent.loadFile] and only calls the super class constructor
  NoteContentFileWrapper._load(Uint8List bytes) : super._load(bytes);

  /// The next 4 bytes after the header are used for the size of the raw [content] size
  int get contentSize => _data.getUint32(NoteContent.baseNoteContentHeaderSize, Endian.big);

  /// next 4 bytes are used for external file size (uncompressed)
  int get externalFileSize => _data.getUint32(NoteContent.baseNoteContentHeaderSize + CONTENT_SIZE_BYTES, Endian.big);

  /// next 4 bytes are used for external file last modified timestamp
  DateTime get fileLastModified {
    final int offset = NoteContent.baseNoteContentHeaderSize + CONTENT_SIZE_BYTES + EXTERNAL_FILE_SIZE_BYTES;
    return DateTime.fromMillisecondsSinceEpoch(_data.getUint64(offset, Endian.big)); // 64 bit
  }

  /// next 4 bytes are used for the length of the external file path that is saved
  int get pathSize {
    final int offset = NoteContent.baseNoteContentHeaderSize +
        CONTENT_SIZE_BYTES +
        EXTERNAL_FILE_SIZE_BYTES +
        FILE_LAST_MODIFIED_BYTES;
    return _data.getUint32(offset, Endian.big);
  }

  /// next variable bytes are used to store the path of the external file
  String get path {
    final int start = headerSize;
    final int end = start + pathSize;
    if (end > _bytes.length) {
      Logger.error("the end of the path part $end would be bigger than the bytes ${_bytes.length}");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    final Uint8List data = Uint8List.sublistView(_bytes, start, end);
    return utf8.decode(data);
  }

  /// returns the file extension of the external file path (.txt, etc)
  String get fileExtension => FileUtils.getExtension(path);

  /// the compressed data (bytes) from the initial external file which is now wrapped inside of the app (decrypted at
  /// this point). this is stored after the header and the path
  Uint8List get content {
    final int start = headerSize + pathSize;
    final int end = start + contentSize;
    if (end > _bytes.length) {
      Logger.error("the end of the content part $end would be bigger than the bytes ${_bytes.length}");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    return Uint8List.sublistView(_bytes, start, end);
  }

  /// because [NoteContentFileWrapper] contains binary data, this will return an empty list instead!
  @override
  Uint8List get text => Uint8List(0); // todo: maybe return the file name and file modify date instead so it can be
  // used for the extended search inside of the app

  @override
  NoteType get noteType => NoteType.FILE_WRAPPER;
}

/// The params used for [NoteContentFileWrapper] with the additional file info
class FileWrapperParams {
  final FilePickerResult fileInfo;

  const FileWrapperParams({
    required this.fileInfo,
  });
}
