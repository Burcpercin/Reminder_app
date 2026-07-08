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
  
  bool _isPasswordVisible = false;

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  void _dogrulamaModaliGoster(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("E-posta Doğrulaması Gerekli"),
        content: const Text(
            "Lütfen e-posta adresinize gönderilen linke tıklayarak hesabınızı doğrulayın.\n\n"
            "Eğer link çalışmıyorsa veya süresi dolduysa, aşağıdaki butondan yeni bir link isteyebilirsiniz."),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                Navigator.pop(context);
                _mesajGoster("Yeni doğrulama maili gönderildi! Lütfen gelen kutunuzu (ve Spam klasörünü) kontrol edin.");
              } catch (e) {
                _mesajGoster("Mail gönderilirken bir hata oluştu. Lütfen biraz bekleyip tekrar deneyin.");
              }
            },
            child: const Text("Tekrar Gönder", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam, Anladım", style: TextStyle(color: Color(0xFF4D319C))),
          ),
        ],
      ),
    );
  }

  // YENİ EKLENEN: ŞİFRE SIFIRLAMA MODALI
  void _sifremiUnuttumModaliGoster() {
    final TextEditingController resetEmailController = TextEditingController();
    // Eğer kullanıcı zaten e-posta yazmışsa, o e-postayı otomatik olarak modala dolduralım
    resetEmailController.text = _emailController.text.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifremi Unuttum"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Hesabınıza ait e-posta adresini girin. Size bir şifre sıfırlama bağlantısı göndereceğiz."),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "E-posta Adresiniz",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D319C)),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                _mesajGoster("Lütfen bir e-posta adresi girin.");
                return;
              }
              try {
                await _authService.sifreSifirlamaMailiGonder(email);
                Navigator.pop(context);
                _mesajGoster("Şifre sıfırlama bağlantısı gönderildi! Lütfen e-postanızı kontrol edin.");
              } catch (e) {
                _mesajGoster("Hata: E-posta adresi geçersiz veya sistemde kayıtlı değil.");
              }
            },
            child: const Text("Şifreyi Sıfırla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _girisYap() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. ADIM: Boş Alan Kontrolü (YENİ EKLENDİ)
    if (email.isEmpty || password.isEmpty) {
      _mesajGoster("Lütfen e-posta ve şifre alanlarını boş bırakmayın.");
      return; // Alanlar boşsa işlemi burada kes, alt satırlara inme.
    }

    // Firebase Giriş İşlemi
    final user = await _authService.girisYap(email, password);

    if (user != null) {
      // Kontrol: Kullanıcı e-postasını onaylamış mı?
      if (!user.emailVerified) {
        await _authService.cikisYap(); 
        _dogrulamaModaliGoster(user);
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
      body: SingleChildScrollView( // Ekranın taşmasını engellemek için eklendi
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFF4D319C)),
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
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            
            // Şifremi unuttum
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sifremiUnuttumModaliGoster,
                child: const Text("Şifremi Unuttum", style: TextStyle(color: Color(0xFF4D319C))),
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D319C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _girisYap,
                child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
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