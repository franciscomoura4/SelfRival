import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/rest_repository.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AppUser?>((ref) => AuthViewModel(RestRepository()));

class AuthViewModel extends StateNotifier<AppUser?> {
  final RestRepository _repository;
  AuthViewModel(this._repository) : super(null) { _checkLoginStatus(); }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    if (userId != null) state = AppUser(id: userId, name: userName ?? 'Runner', email: '');
  }

  // Connects to Firebase REST to save the user
  Future<void> login(String email, String password) async {
    try {
      final user = await _repository.loginOrCreateUser(email, email.split('@').first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      state = user;
    } catch (e) {
      print("Login failed: $e");
      rethrow; // Propagate error so UI can handle it
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    state = null;
  }
}