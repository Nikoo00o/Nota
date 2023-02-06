class HiveBoxConfiguration {
  /// The file path to the box file from the Hive home directory.
  ///
  /// The Hive home directory must be set with a call to Hive.init at the start of the program!
  final String name;

  /// Set this to true if only the keys should be loaded in memory and the values should be loaded on demand
  final bool isLazy;

  /// If not null, a base64 encoded key to encrypt/decrypt the box. Otherwise it will be unencrypted.
  ///
  /// The key itself should be stored in the secureStorage.
  final String? encryptionKey;

  const HiveBoxConfiguration({
    required this.name,
    required this.isLazy,
    this.encryptionKey,
  });
}
