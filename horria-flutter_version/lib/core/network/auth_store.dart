class AuthStore {
  static final AuthStore _instance = AuthStore._internal();
  factory AuthStore() => _instance;

  AuthStore._internal();

  int? userId;
  String? sessionId;
  String? userName;
  String? greeting;

  void setSession(String? token, {int? id, String? name, String? userGreeting}) {
    if (token != null) {
      sessionId = token;
      userId = id ?? int.tryParse(token); // Keeping this if userId happens to be same as token, though token is usually string uuid
    }
    userName = name;
    greeting = userGreeting;
  }

  void logout() {
    userId = null;
    sessionId = null;
    userName = null;
    greeting = null;
  }
}
