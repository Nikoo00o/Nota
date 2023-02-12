/// The transfer status which side needs to update the note used for the note transfer.
///
/// You can use the getters on the enum [clientNeedsUpdate] and [serverNeedsUpdate] to decide.
enum NoteTransferStatus {
  /// The client did not have the note saved
  CLIENT_NEEDS_NEW,

  /// The server had a newer time stamp for the note
  CLIENT_NEEDS_UPDATE,

  /// The client had a newer time stamp for the note
  SERVER_NEEDS_UPDATE,

  /// The server did not have the note saved
  SERVER_NEEDS_NEW;

  factory NoteTransferStatus.fromString(String data) {
    return values.firstWhere((NoteTransferStatus element) => element.name == data);
  }

  /// If the client needs a new version of the note
  bool get clientNeedsUpdate => index <= CLIENT_NEEDS_UPDATE.index;

  /// If the server needs a new version of the note
  bool get serverNeedsUpdate => index >= SERVER_NEEDS_UPDATE.index;

  @override
  String toString() {
    return name;
  }
}
