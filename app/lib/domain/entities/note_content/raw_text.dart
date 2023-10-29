part of "note_content.dart";

/// A raw text note with the type [NoteType.RAW_TEXT]. For loading, use [NoteContent.loadFile] and for saving use
/// [NoteContent.saveFile]
final class NoteContentRawText extends NoteContent {

  /// next 4 bytes part of the header
  static const int TEXT_SIZE_BYTES = 4;

  /// a maximum of 4 gb text is supported inside of notes
  static const int MAX_TEXT_BYTES = 4000000000;

  /// the current version for when writing raw text files (used for migration)
  static const int RAW_TEXT_VERSION = 1;

  /// should be the same as [headerSize] and contain all static attributes
  static int get staticHeaderSize => NoteContent.baseNoteContentHeaderSize + TEXT_SIZE_BYTES;

  /// Internally used to initialize the bytes (by copying the reference) and also the header fields!
  /// This initializes the [textSize] and the [text] part of the [bytes] itself by copying over the parts of
  /// [decryptedContent]
  ///
  /// The [bytes] must be created to be large enough to fit the header fields in addition to any other content
  ///
  /// This also calls [NoteContent._save] and is called by [NoteContentRawText._saveFile]
  NoteContentRawText._save({
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
      Logger.error("text size $textSize, was bigger, or equal to ${MAX_TEXT_BYTES / 1000000000} GB");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    final int combined = headerSize + textSize;
    if (_bytes.length < combined) {
      Logger.error("bytes length ${_bytes.length} is smaller than header size and text size $combined");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  /// Creates a new [NoteContentRawText] for [NoteType.RAW_TEXT] for the [decryptedContent] of the text inside of the
  /// app.
  /// This will create the [_bytes] list with the header information and copies the [decryptedContent] into it
  factory NoteContentRawText._saveFile({required List<int> decryptedContent}) {
    final int headerSize = staticHeaderSize; // full static header size
    final int textSize = decryptedContent.length;
    final Uint8List bytes = Uint8List(headerSize + textSize); // initialize bytes with correct size
    return NoteContentRawText._save(
      bytes: bytes,
      headerSize: headerSize,
      textSize: textSize,
      decryptedContent: decryptedContent,
    );
  }

  /// Used internally by [NoteContent.loadFile] and only calls the super class constructor
  NoteContentRawText._load(Uint8List bytes) : super._load(bytes);

  /// The next 4 bytes after the header are used for the size of the raw [text] size
  int get textSize => _data.getUint32(NoteContent.baseNoteContentHeaderSize, Endian.big);

  /// the text directly follows the header, so it has an offset of [headerSize] and a size of [headerSize].
  ///
  /// It only returns a reference to the part of the [_bytes]!
  @override
  Uint8List get text {
    final int start = headerSize;
    final int end = start + textSize;
    if (end > _bytes.length) {
      Logger.error("the end of the text part $end would be bigger than the bytes ${_bytes.length}");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    return Uint8List.sublistView(_bytes, start, end);
  }

  @override
  NoteType get noteType => NoteType.RAW_TEXT;
}
