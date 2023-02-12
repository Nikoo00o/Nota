/// The transfer status which side needs to update the note used for the note transfer
enum NoteTransferStatus {
  /// The server had a newer time stamp for the note
  CLIENT_NEEDS_UPDATE,

  /// The client had a newer time stamp for the note
  SERVER_NEEDS_UPDATE;

  factory NoteTransferStatus.fromString(String data) {
    return values.firstWhere((NoteTransferStatus element) => element.name == data);
  }

  @override
  String toString() {
    return name;
  }
}
