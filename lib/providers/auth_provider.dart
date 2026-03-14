import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/firebase_service.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  final _auth = FirebaseAuth.instance;
  final _service = FirebaseService();

  @override
  User? build() {
    _auth.authStateChanges().listen((user) {
      state = user;
    });
    return _auth.currentUser;
  }

  bool get isAuthenticated => state != null;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await _service.ensureUserDoc(cred.user!.uid, email, name);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'invalid-email' => 'Please enter a valid email.',
      'email-already-in-use' => 'Email already registered.',
      'weak-password' => 'Password must be at least 6 characters.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
