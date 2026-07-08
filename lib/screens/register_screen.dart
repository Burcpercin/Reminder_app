import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();

  // Her iki şifre alanını da tek bir noktadan kontrol edecek tek değişken
  bool _isPasswordVisible = false;

  void _kaydiTamamla() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Boş Alan Kontrolü
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen e-posta ve şifre alanlarını boş bırakmayın."),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Alanlardan biri bile boşsa işlemi burada kes
    }

    // Şifrelerin eşleşip eşleşmediğini kontrol et
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Şifreler eşleşmiyor. Lütfen kontrol edin."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Eşleşmiyorsa işlemi durdur
    }

    // Firebase Kayıt İşlemi
    final user = await _authService.kayitOl(email, password);

    if (user != null) {
      await _authService.cikisYap(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt başarılı! Lütfen e-postanızı doğruladıktan sonra giriş yapın."),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarısız. Bilgileri kontrol edin.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Hesap Oluştur"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_alt_1, size: 80, color: Color(0xFF4D319C)),
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
            
            // BİRİNCİ ŞİFRE ALANI
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Şifre (En az 6 karakter)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible; // İkisini birden etkiler
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // İKİNCİ ŞİFRE ALANI
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isPasswordVisible, // Aynı değişken kullanılıyor
              decoration: InputDecoration(
                labelText: "Şifreyi Tekrar Girin",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D319C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _kaydiTamamla,
                child: const Text("Kayıt Ol", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}