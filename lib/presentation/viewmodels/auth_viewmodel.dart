import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class AuthViewModel extends StateNotifier<AppUser?> {
  AuthViewModel() : super(null) {
    _checkLoginStatus();
  }

  final AppUser _dummyUser = AppUser(id: 'u1', name: 'Runner 01', email: 'test@test.com');

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      state = _dummyUser;
    }
  }

  Future<void> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _dummyUser.id);
    state = _dummyUser;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthViewModel, AppUser?>((ref) => AuthViewModel());