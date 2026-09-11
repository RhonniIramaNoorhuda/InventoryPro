import "package:firebase_auth/firebase_auth.dart";

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "email-already-in-use":
          message = "Email sudah terdaftar";
          break;
        case "invalid-email":
          message = "Format email salah";
          break;
        case "weak-password":
          message = "Password terlalu lemah";
          break;
        default:
          message = "Gagal mendaftar. Silakan coba lagi.";
      }
      throw Exception(message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        throw Exception("Silakan login kembali untuk menghapus akun");
      }
      throw Exception("Gagal menghapus akun. Silakan coba lagi.");
    }
  }
}
