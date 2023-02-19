enum RequiredLoginStatus {
  /// A full server side login with username+password is needed
  REMOTE,

  /// Only a local login with the password is needed
  LOCAL,

  /// No login is needed (auto login)
  NONE;
}
