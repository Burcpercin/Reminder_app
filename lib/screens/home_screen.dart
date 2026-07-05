import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // Çıkış yapma fonksiyonu
  void _cikisYap() async {
    await _authService.cikisYap();
    
    // Çıkış yaptıktan sonra login ekranına geri dön ve geçmişi sil
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hatırlatıcılarım"),
        centerTitle: true,
        actions: [
          // Çıkış butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: const Center(
        child: Text(
          "Burası yakında hatırlatıcılarınla dolacak!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      // Not ekleme butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Not ekleme penceresi (Test için)
          print("Not ekleme butonuna basıldı");
        },
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}