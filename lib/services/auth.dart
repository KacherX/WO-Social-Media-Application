import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  String? getUserUid() {
    if (currentUser != null) {
      return currentUser!.uid;
    } else {
      return null;
    }
  }

  // Register
  Future<User?> createUser(
      {required String email,
      required String password,
      required String username}) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    await currentUser!.updateDisplayName(username);
    sendEmailVerification();
    return currentUser;
  }

  // Login
  Future<User?> login({required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return currentUser;
  }

  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    if (currentUser != null && currentUser!.emailVerified == false) {
      await currentUser!.sendEmailVerification();
    }
  }
}
