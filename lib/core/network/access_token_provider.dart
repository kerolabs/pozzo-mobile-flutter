/// Gives the network layer the session token without depending on how Identity & Access keeps it.
abstract class AccessTokenProvider {
  /// The token of the open session, or null when nobody is signed in.
  String? get currentToken;

  /// Called when the backend rejects the token, so the session is closed.
  void onUnauthorized();
}
