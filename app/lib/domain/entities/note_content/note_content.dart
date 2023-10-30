import 'dart:convert';
import 'dart:typed_data';

import 'package:app/domain/entities/file_picker_result.dart';
import 'package:path/path.dart' as p;
import 'package:shared/core/config/shared_config.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/note_type.dart';
import 'package:shared/core/exceptions/exceptions.dart';
import 'package:shared/core/utils/file_utils.dart';
import 'package:shared/core/utils/logger/logger.dart';

part "raw_text.dart";

part "file_wrapper.dart";

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
/// This can return a [FileException] with [ErrorCodes.INVALID_PARAMS], or [ErrorCodes.FILE_TO_BIG].
///
///
/// To access the full [_bytes] for saving, use [fullBytes] and to access only the content bytes for reading, use
/// [text] if the note content does not contain binary data
sealed class NoteContent {
  /// The raw decrypted bytes of the note file (the full content with no offsets including the header)!
  /// The public access should use [text] to get only the text content bytes (if the note content does not include
  /// binary data)
  final Uint8List _bytes;

  /// The first 2 bytes are used for the full header size. This is stored inside of the note itself. This will be at
  /// least as big as [baseNoteContentHeaderSize], but can be bigger!
  ///
  /// It represents the full dynamic size of the complete header fields (including those of the subclasses). these
  /// will be all static computed sizes for attributes (no variable ones)
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
  /// ui for the content search and also of course for displaying text in a text edit controller! note content types
  /// with binary data should return an empty list instead!
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
  /// the [fileWrapperParams] are only used used for [NoteType.FILE_WRAPPER]
  // todo: for additional note types, add more nullable optional params
  factory NoteContent.saveFile({
    required List<int> decryptedContent,
    required NoteType noteType,
    FileWrapperParams? fileWrapperParams,
  }) {
    if (noteType == NoteType.FOLDER) {
      Logger.error("tried to save a file while the note type was folder: $noteType");
    }
    if ((noteType == NoteType.FILE_WRAPPER) != (fileWrapperParams != null)) {
      Logger.error("tried to save a file wrapper with no params, or a different type with file wrapper params");
      throw const FileException(message: ErrorCodes.INVALID_PARAMS);
    }
    // this must be adjusted for every note type and subclass of this
    return switch (noteType) {
      NoteType.RAW_TEXT => NoteContentRawText._saveFile(decryptedContent: decryptedContent),
      NoteType.FOLDER => throw const FileException(message: ErrorCodes.INVALID_PARAMS),
      NoteType.FILE_WRAPPER =>
        NoteContentFileWrapper._saveFile(decryptedContent: decryptedContent, params: fileWrapperParams!),
    };
  }
}
