import 'dart:typed_data';

import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/logger/logger.dart';

/// This is the representation of the decrypted note content (so what is stored inside of the file).
///
/// Individual parts of the bytes are accessed with offsets and Uint8List's! These parts could include more.
///
/// Depending on the [NoteType], a different subclass of this is used. Each subclass must override [noteType]. Use
/// the factory constructor [NoteContent.loadFile] to return the fitting sub type of this for a loaded note file (the
/// decrypted bytes of it).
///
/// For saving, or creating the decrypted bytes that are saved inside of the note file, use the [NoteContent.save]
/// constructors of the sub classes. If there are no additional params needed, then use the factory constructor
/// [NoteContent.saveFile]
///
/// This can return a [FileException] with [ErrorCodes.INVALID_PARAMS].
///
///
/// To access the full [_bytes] for saving, use [fullBytes] and to access only the content bytes for reading, use [text]
sealed class NoteContent {
  /// The raw decrypted bytes of the note file (the full content with no offsets including the header)!
  /// The public access should use [text]
  final Uint8List _bytes;

  /// The first 2 bytes are used for the full header size. This is stored inside of the note itself. This will be at
  /// least as big as [baseNoteContentHeaderSize], but can be bigger!
  ///
  /// It represents the full dynamic size of the complete header fields (including those of the subclasses)
  int get headerSize => _data.getUint16(0, Endian.big);

  /// The next 2 bytes are used for the version
  int get version => _data.getUint16(HEADER_SIZE_BYTES, Endian.big);

  static const int HEADER_SIZE_BYTES = 2;
  static const int VERSION_BYTES = 2;

  /// Every header is at least this big (this contains the [HEADER_SIZE_BYTES] and [VERSION_BYTES]
  static int get baseNoteContentHeaderSize => HEADER_SIZE_BYTES + VERSION_BYTES;

  /// use one of the [NoteContent.save] constructors of the sub classes instead!
  NoteContent.save(Uint8List bytes) : _bytes = bytes {
    throw UnimplementedError();
  }

  /// Used internally by the [NoteContent.save] constructors of the sub classes to also save [headerSize] and [version]
  /// inside of [_bytes]!
  NoteContent._save(Uint8List bytes, int headerSize, int version) : _bytes = bytes {
    _checkBytes();
    _data.setUint16(0, headerSize, Endian.big);
    _data.setUint16(HEADER_SIZE_BYTES, version, Endian.big);
    _checkBaseHeaderFields();
  }

  /// Used internally by [NoteContent.loadFile] to initialize the [_bytes] as a reference (for which [headerSize] and
  /// [version] will be loaded from)
  NoteContent._load(Uint8List bytes) : _bytes = bytes {
    _checkBytes();
    _checkBaseHeaderFields();
  }

  void _checkBytes() {
    if (_bytes.length < baseNoteContentHeaderSize) {
      Logger.error("bytes are smaller than base $baseNoteContentHeaderSize");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  void _checkBaseHeaderFields() {
    if (headerSize < 0 || version < 0) {
      Logger.error("header size $headerSize, or version $version is less than 0 ");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    if (headerSize > _bytes.length || headerSize < baseNoteContentHeaderSize) {
      Logger.error("header size $headerSize is bigger than ${_bytes.length}, or less than $baseNoteContentHeaderSize");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
  }

  /// For byte manipulation of the [_bytes] a direct access to the byte buffer
  ByteData get _data => _bytes.buffer.asByteData();

  /// returns if the [text] is empty!!! this does not check the [_bytes], because they are never empty!!!
  bool get isEmpty => text.isEmpty;

  /// returns if the [text] is not empty!!! this does not check the [_bytes], because they are never empty !!!
  bool get isNotEmpty => text.isEmpty == false;

  /// This needs to be overridden in the sub classes!
  NoteType get noteType {
    Logger.error("tried to get the note type of $this, but it was not overridden");
    throw const FileException(message: ErrorCodes.INVALID_PARAMS);
  }

  /// this returns the full [_bytes] including the header part and should be used to save the data into a file.
  Uint8List get fullBytes => _bytes;

  /// This needs to be overridden in the sub classes to return the main data part of the [_bytes] with the correct
  /// offset! This is used to get the data part without the headers which is used to retrieve the data inside of the
  /// ui, etc!
  Uint8List get text {
    Logger.error("tried to get the text of $this, but it was not overridden");
    throw const FileException(message: ErrorCodes.INVALID_PARAMS);
  }

  /// This is called when loading decrypted [_bytes] from a note file. It will reference those bytes internally as a
  /// reference and perform some error checks and return the correct sub type of [NoteContent] for the [noteType]
  factory NoteContent.loadFile({required Uint8List bytes, required NoteType noteType}) {
    if (noteType == NoteType.FOLDER) {
      Logger.error("tried to load a file while the note type was folder: $noteType");
    }
    // this must be adjusted for every note type and subclass of this
    return switch (noteType) {
      NoteType.RAW_TEXT => NoteContentRawText._load(bytes),
      NoteType.FOLDER => throw const FileException(message: ErrorCodes.INVALID_PARAMS),
      NoteType.FILE_WRAPPER => NoteContentFileWrapper._load(bytes),
    };
  }

  /// This is called when wanting to save decrypted [decryptedContent] to a note file. It will create a copy within
  /// the own [_bytes] and perform some error checks and return the correct sub type of [NoteContent] for the [noteType].
  ///
  /// only for [NoteType.FILE_WRAPPER], the [fileWrapperExtension] param is the file extension of the file name after
  /// the "."
  // todo: If there are additional params, consider adding additional nullable params to the factory constructor, or
  // using the constructor of sub types directly
  factory NoteContent.saveFile({
    required List<int> decryptedContent,
    required NoteType noteType,
    String? fileWrapperExtension,
  }) {
    if (noteType == NoteType.FOLDER) {
      Logger.error("tried to save a file while the note type was folder: $noteType");
    }
    if (noteType == NoteType.FILE_WRAPPER && fileWrapperExtension == null) {
      Logger.error("tried to save a file wrapper with no extension");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    // this must be adjusted for every note type and subclass of this
    return switch (noteType) {
      NoteType.RAW_TEXT => NoteContentRawText._saveFile(decryptedContent: decryptedContent),
      NoteType.FOLDER => throw const FileException(message: ErrorCodes.INVALID_PARAMS),
      NoteType.FILE_WRAPPER => NoteContentFileWrapper._saveFile(decryptedContent: decryptedContent),
    };
  }
}

/// A raw text note with the type [NoteType.RAW_TEXT]. For loading, use [NoteContent.loadFile] and for saving use
/// [NoteContent.saveFile]
final class NoteContentRawText extends NoteContent {
  /// The next 4 bytes are used for the size of the raw [text] which directly follows the header
  int get textSize => _data.getUint32(NoteContent.baseNoteContentHeaderSize, Endian.big);

  static const int TEXT_SIZE_BYTES = 4;

  /// a maximum of 4 gb text is supported inside of notes
  static const int MAX_TEXT_BYTES = 4000000000;

  /// The [NoteContent.baseNoteContentHeaderSize] with the addition of the [TEXT_SIZE_BYTES] 4 bytes. So 8 bytes
  static int get headerSizeIncludingText => NoteContent.baseNoteContentHeaderSize + TEXT_SIZE_BYTES;

  /// the current version for when writing raw text files (used for migration)
  static const int RAW_TEXT_VERSION = 1;

  /// Internally used to initialize the bytes (by copying the reference) and also the header fields!
  /// This initializes the [textSize] and the [text] part of the [bytes] itself by copying over the parts of
  /// [decryptedContent]
  ///
  /// The [bytes] must be created to be large enough to fit the header fields in addition to any other content
  ///
  /// This also calls [NoteContentRawText._save] and is called by [NoteContentRawText._saveFile]
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
      Logger.error("text size $textSize, was bigger, or equal to 4 GB");
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
    final int headerSize = headerSizeIncludingText;
    final int textSize = decryptedContent.length;
    final Uint8List bytes = Uint8List(headerSize + textSize);
    return NoteContentRawText._save(
      bytes: bytes,
      headerSize: headerSize,
      textSize: textSize,
      decryptedContent: decryptedContent,
    );
  }

  /// Used internally by [NoteContent.loadFile] and only calls the super class constructor
  NoteContentRawText._load(Uint8List bytes) : super._load(bytes);

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

/// A raw text note with the type [NoteType.FILE_WRAPPER]. For loading, use [NoteContent.loadFile] and for saving use
/// [NoteContent.saveFile]
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

  // todo: change and implement

  /// Internally used to initialize the bytes (by copying the reference) and also the header fields!
  /// This initializes the [textSize] and the [text] part of the [bytes] itself by copying over the parts of
  /// [decryptedContent]
  ///
  /// The [bytes] must be created to be large enough to fit the header fields in addition to any other content
  ///
  /// This also calls [NoteContentRawText._save] and is called by [NoteContentRawText._saveFile]
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

  /// Creates a new [NoteContentRawText] for [NoteType.RAW_TEXT] for the [decryptedContent] of the text inside of the
  /// app.
  /// This will create the [_bytes] list with the header information and copies the [decryptedContent] into it
  factory NoteContentFileWrapper._saveFile({required List<int> decryptedContent}) {
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
  NoteType get noteType => NoteType.FILE_WRAPPER;
}
