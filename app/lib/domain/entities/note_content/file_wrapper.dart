part of "note_content.dart";

/// A raw text note with the type [NoteType.FILE_WRAPPER]. For loading, use [NoteContent.loadFile] and for saving use
/// [NoteContent.saveFile].
///
/// For this the [text] returns the file bytes
final class NoteContentFileWrapper extends NoteContent {
  /// The next 4 bytes are used for the size of the raw [text] which directly follows the header
  int get textSize => _data.getUint32(NoteContent.baseNoteContentHeaderSize, Endian.big);

  static const int TEXT_SIZE_BYTES = 4;

  /// a maximum of 4 gb text is supported inside of notes
  static const int MAX_TEXT_BYTES = 4000000000;

  /// The [NoteContent.baseNoteContentHeaderSize] with the addition of the [TEXT_SIZE_BYTES] 4 bytes. So 8 bytes
  static int get headerSizeIncludingText => NoteContent.baseNoteContentHeaderSize + TEXT_SIZE_BYTES;

  /// the current version for when writing raw text files (used for migration)
  static const int RAW_TEXT_VERSION = 1;

  // todo: change and implement until _load

  /// Internally used to initialize the bytes (by copying the reference) and also the header fields!
  /// This initializes the [textSize] and the [text] part of the [bytes] itself by copying over the parts of
  /// [decryptedContent]
  ///
  /// The [bytes] must be created to be large enough to fit the header fields in addition to any other content
  ///
  /// This also calls [NoteContent._save] and is called by [NoteContentFileWrapper._saveFile]
  NoteContentFileWrapper._save({
    required Uint8List bytes,
    required int headerSize,
    required int textSize,
    required List<int> decryptedContent,
  }) : super._save(bytes, headerSize, RAW_TEXT_VERSION) {
    _data.setUint32(NoteContent.baseNoteContentHeaderSize, textSize, Endian.big);
    _checkRawTextHeaderFields();
    for (int i = 0; i < decryptedContent.length; ++i) {
      bytes[i + headerSize] = decryptedContent[i]; // headerSize is the offset for the text part
    }
  }

  void _checkRawTextHeaderFields() {
    if (textSize >= MAX_TEXT_BYTES) {
      Logger.error("text size $textSize, was bigger, or equal to 4 GB");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    final int combined = headerSize + textSize;
    if (_bytes.length < combined) {
      Logger.error("bytes length ${_bytes.length} is smaller than header size and text size $combined");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  /// Creates a new [NoteContentFileWrapper] for [NoteType.FILE_WRAPPER] for the [decryptedContent] of the text inside
  /// of the app.
  /// This will create the [_bytes] list with the header information and copies the [decryptedContent] into it.
  /// The [fileWrapperParams] contains additional data to be saved into the [_bytes]
  factory NoteContentFileWrapper._saveFile({
    required List<int> decryptedContent,
    required FileWrapperParams params,
  }) {
    final int headerSize = headerSizeIncludingText;
    final int textSize = decryptedContent.length;
    final Uint8List bytes = Uint8List(headerSize + textSize);
    return NoteContentFileWrapper._save(
      bytes: bytes,
      headerSize: headerSize,
      textSize: textSize,
      decryptedContent: decryptedContent,
    );
  }

  /// Used internally by [NoteContent.loadFile] and only calls the super class constructor
  NoteContentFileWrapper._load(Uint8List bytes) : super._load(bytes);

  /// because [NoteContentFileWrapper] contains binary data, this will return an empty list instead!
  @override
  Uint8List get text => Uint8List(0);

  @override
  NoteType get noteType => NoteType.FILE_WRAPPER;
}

/// The params used to
class FileWrapperParams {
  // todo: add file info that is needed
}
