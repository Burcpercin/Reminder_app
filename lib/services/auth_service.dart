import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

// Sign Up
  Future<User?> kayitOl(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Kullanıcıya doğrulama e-postası gönderir
      await userCredential.user?.sendEmailVerification();
      
      return userCredential.user;
    } catch (e) {
      print("Kayıt Servisi Hatası: $e");
      return null;
    }
  }

  // Sign In
  Future<User?> girisYap(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Giriş Servisi Hatası: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> cikisYap() async {
    await _auth.signOut();
  }
}