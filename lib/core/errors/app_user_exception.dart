/// A domain error whose message is already suitable for the user interface.
abstract interface class AppUserException {
  String get message;
}
