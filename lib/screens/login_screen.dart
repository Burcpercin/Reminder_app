import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();

  // Ekranın altında küçük bildirimler göstermek için
  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  // Doğrulama modalı
  void _dogrulamaModaliGoster(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("E-posta Doğrulaması Gerekli"),
        content: const Text(
            "Lütfen e-posta adresinize gönderilen linke tıklayarak hesabınızı doğrulayın.\n\n"
            "Eğer link çalışmıyorsa veya süresi dolduysa, aşağıdaki butondan yeni bir link isteyebilirsiniz."),
        actions: [
          // Linki yeniden gönderme butonu
          TextButton(
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                Navigator.pop(context); // Modalı kapat
                _mesajGoster("Yeni doğrulama maili gönderildi! Lütfen gelen kutunuzu (ve Spam klasörünü) kontrol edin.");
              } catch (e) {
                _mesajGoster("Mail gönderilirken bir hata oluştu. Lütfen biraz bekleyip tekrar deneyin.");
              }
            },
            child: const Text("Tekrar Gönder", style: TextStyle(color: Colors.orange)),
          ),
          // KAPATMA BUTONU
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam, Anladım", style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  // Giriş yapma fonksiyonu
  Future<void> _girisYap() async {
    final user = await _authService.girisYap(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      // Kontrol: Kullanıcı e-postasını onaylamış mı?
      if (!user.emailVerified) {
        await _authService.cikisYap(); 
        _dogrulamaModaliGoster(user); // 'user' objesini modala aktarıyoruz
        return; 
      }
      

      // Her şey onaylıysa Ana Ekrana yönlendir
      _mesajGoster("Giriş başarılı! Hoş geldin.");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      _mesajGoster("Giriş başarısız. Lütfen bilgileri kontrol et.");
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

            // Kayıt Ol yönlendirme butonu
            TextButton(
              onPressed: () {
                // Burada kullanıcıyı yeni yaptığımız Kayıt Ol sayfasına yönlendiriyoruz
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text("Hesabın yok mu? Kayıt Ol", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}