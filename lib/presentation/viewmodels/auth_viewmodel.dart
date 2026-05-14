import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/rest_repository.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AppUser?>((ref) => AuthViewModel(RestRepository()));

class AuthViewModel extends StateNotifier<AppUser?> {
  final RestRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthViewModel(this._repository) : super(null) {
    // Restore session on startup and listen for future auth state changes
    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        state = null;
      } else {
        final displayName = firebaseUser.displayName;
        final emailPrefix = firebaseUser.email!.split('@').first;
        state = AppUser(
          id: firebaseUser.uid,
          name: (displayName != null && displayName.isNotEmpty) ? displayName : emailPrefix,
          email: firebaseUser.email!,
        );
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // authStateChanges listener above will update state automatically
  }

  Future<void> signUp(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user!;
    await user.updateDisplayName(name);
    await user.reload(); // Ensure authStateChanges fires with the updated displayName
    // Persist user profile in Realtime Database
    await _repository.saveUserProfile(user.uid, name, email);
    // authStateChanges listener above will update state automatically
  }

  Future<void> sendPasswordReset(String email) async {
    // NOTE: For this check to work, "Email Enumeration Protection" must be
    // disabled in Firebase Console → Authentication → Settings → User actions.
    // With it enabled, fetchSignInMethodsForEmail always returns [] (by design).
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.isEmpty) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
    // authStateChanges listener above will set state to null automatically
  }
}