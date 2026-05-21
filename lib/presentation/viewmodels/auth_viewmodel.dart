import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/rest_repository.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AppUser?>((ref) => AuthViewModel(RestRepository()));

class AuthViewModel extends StateNotifier<AppUser?> {
  final RestRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthViewModel(this._repository) : super(null) {
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
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw Exception('Incorrect email or password.');
      }
      throw Exception(e.message ?? 'An error occurred during sign in.');
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(name);
      await user.reload(); 
      await _repository.saveUserProfile(user.uid, name, email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password is too weak.');
      }
      throw Exception(e.message ?? 'An error occurred during sign up.');
    }
  }

  /// Sends a password reset email.
  /// Due to Firebase security policies, this will succeed silently 
  /// even if the email does not exist in the database.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('The email format is invalid.');
      }
      throw Exception('An error occurred while sending the reset email.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}