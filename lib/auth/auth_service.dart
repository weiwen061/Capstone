import 'user_model.dart';

class AuthService {
  static final List<UserModel> _users = [];

  static bool register(String email, String password) {
    final exists = _users.any((u) => u.email == email);
    if (exists) return false;

    _users.add(UserModel(email: email, password: password));
    return true;
  }

  static bool login(String email, String password) {
    return _users.any(
      (u) => u.email == email && u.password == password,
    );
  }
}