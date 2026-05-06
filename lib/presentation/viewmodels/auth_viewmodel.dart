import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/mock_repository.dart';

// This provider manages the user's login state (null means logged out)
class AuthViewModel extends StateNotifier<AppUser?> {
  AuthViewModel() : super(null) {
    _loadSavedSession();
  }

  // 1. Check if the user was logged in previously
  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id');

    if (savedUserId != null) {
      // For now, just load our mock user. Later, fetch from Firebase.
      state = MockRepository.currentUser;
    }
  }

  // 2. Login Method
  Future<void> login(String email, String password) async {
    // Mocking network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate successful login
    final user = MockRepository.currentUser;
    state = user;

    // Save session locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
  }

  // 3. Logout Method
  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
}

// Make the ViewModel available to the rest of the app
final authProvider = StateNotifierProvider<AuthViewModel, AppUser?>((ref) {
  return AuthViewModel();
});