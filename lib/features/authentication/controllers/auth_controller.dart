import 'package:helmet_app/features/authentication/repository/auth_repository.dart';

class AuthController {
  final AuthRepository _repo = AuthRepository();

  Future<String?> login(String email, String password) async {
    try {
      final res = await _repo.signIn(email: email, password: password);

      if (res.user != null) {
        return null; // success
      } else {
        return "Login failed";
      }
    } catch (e) {
      return "Invalid email or password";
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _repo.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        return null; // success
      } else {
        return "Signup failed";
      }
    } catch (e) {
      return "Could not sign up";
    }
  }
}