import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Backend işçimizi buraya çağırdık

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  // Giriş yapma fonksiyonu
  Future<void> _girisYap() async {
    final user = await _authService.girisYap(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      _mesajGoster("Giriş başarılı! Hoş geldin.");
      // Başarılı olunca Hatırlatıcılar (Ana) sayfasına yönlendirilecek
    } else {
      _mesajGoster("Giriş başarısız. Lütfen bilgileri kontrol et.");
    }
  }

  // Kullanıcı kayıt fonksiyonu
  Future<void> _kayitOl() async {
    final user = await _authService.kayitOl(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      _mesajGoster("Kayıt başarılı! Giriş yapıldı.");
      // Başarılı olunca Hatırlatıcılar sayfasında kullanıcıya özel repo açılacak
    } else {
      _mesajGoster("Kayıt başarısız. Hata konsola yazdırıldı.");
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
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _girisYap,
                child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 15),

            TextButton(
              onPressed: _kayitOl,
              child: const Text("Hesabın yok mu? Yeni Kayıt Ol", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}