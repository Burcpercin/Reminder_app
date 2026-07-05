import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Kimlik doğrulama paketi eklendi
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anımsatıcı',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const LoginScreen(),
    );
  }
}

// Durumu değişebilen ekran (StatefulWidget) yaptık çünkü içine yazı yazacağız
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Kutucuklardaki yazıları okumak için kumandalar (Controllers)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Firebase Auth motorunu çağırıyoruz
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hata veya başarı mesajlarını ekranda göstermek için küçük bir yardımcı araç
  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  // GİRİŞ YAPMA FONKSİYONU
  Future<void> _girisYap() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _mesajGoster("Başarıyla giriş yapıldı!");
      // TODO: Başarılı olunca Hatırlatıcılar (Ana) sayfasına yönlendirilecek
    } on FirebaseAuthException catch (e) {
      _mesajGoster("Giriş Hatası: ${e.message}");
    }
  }

  // YENİ KAYIT OLMA FONKSİYONU
  Future<void> _kayitOl() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _mesajGoster("Hesap oluşturuldu ve giriş yapıldı!");
      // TODO: Başarılı olunca Hatırlatıcılar sayfasında kullanıcıya özel depo açılacak
    } on FirebaseAuthException catch (e) {
      _mesajGoster("Kayıt Hatası: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giriş Yap"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.deepPurpleAccent),
            const SizedBox(height: 40),
            
            // E-posta Kutucuğu (Controller bağlandı)
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            
            // Şifre Kutucuğu (Controller bağlandı)
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 40),
            
            // GİRİŞ YAP Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _girisYap, // Giriş fonksiyonunu tetikler
                child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 15),

            // KAYIT OL Butonu (Görünmez arkaplanlı)
            TextButton(
              onPressed: _kayitOl, // Kayıt fonksiyonunu tetikler
              child: const Text("Hesabın yok mu? Yeni Kayıt Ol", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}