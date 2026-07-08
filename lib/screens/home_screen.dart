import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/reminder_model.dart';
import 'login_screen.dart';
import 'add_reminder_screen.dart';
import 'edit_reminder_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // TARİH FORMATLAMA YARDIMCISI
  String _tarihFormatla(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // ÇIKIŞ YAPMA
  void _cikisYap() async {
    await _authService.cikisYap();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Hatırlatıcılarım", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 190, 17, 17)),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ Color(0xFF3E277E), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<ReminderModel>>(
            stream: _firestoreService.getReminders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (snapshot.hasError) {
                return Center(child: Text("Bir hata oluştu: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final reminders = snapshot.data ?? [];

              if (reminders.isEmpty) {
                return const Center(
                  child: Text(
                    "Henüz bir hatırlatıcı eklemedin.\nHadi bir tane oluştur!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];

                  Color priorityColor;
                  if (reminder.priority == 2) {
                    priorityColor = Colors.redAccent;
                  } else if (reminder.priority == 1) {
                    priorityColor = Colors.orangeAccent;
                  } else {
                    priorityColor = Colors.lightBlueAccent;
                  }

                  if (reminder.isCompleted) {
                    priorityColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    // Kaydırarak silme widget
                    child: Dismissible(
                      key: Key(reminder.id),
                      // Her iki yöne kaydırmaya izin veriyoruz
                      direction: DismissDirection.horizontal, 
                      
                      // 1. YÖN: Soldan Sağa Kaydırma (Düzenle Arka Planı)
                      background: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      
                      // 2. YÖN: Sağdan Sola Kaydırma (Silme Arka Planı)
                      secondaryBackground: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      
                      // KAYDIRMA İŞLEMİNİ YAKALAMA VE YÖNLENDİRME
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Soldan sağa kaydırıldı: Düzenleme ekranını aç
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditReminderScreen(reminder: reminder),
                            ),
                          );
                          // Öğenin listeden silinmemesi (yerine geri sekmesi) için false döndürüyoruz
                          return false; 
                          
                        } else if (direction == DismissDirection.endToStart) {
                          // Sağdan sola kaydırıldı: Silme işlemi onayı
                          return true; // true döndürerek öğenin ekrandan kaybolmasına izin veriyoruz
                        }
                        return false;
                      },
                      
                      // SİLİNME İŞLEMİ TAMAMLANDIĞINDA TETİKLENEN KISIM
                      onDismissed: (direction) {
                        // Sadece sağdan sola kaydırılıp true döndüğünde burası çalışır
                        if (direction == DismissDirection.endToStart) {
                          _firestoreService.deleteReminder(reminder.id);
                          NotificationService().bildirimIptalEt(reminder.id.hashCode);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Hatırlatıcı başarıyla silindi."),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      // KARTIN KENDİSİ
                      child: _buildGlassCard(reminder, priorityColor),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReminderScreen()),
          );
        },
        backgroundColor: Color(0xFF4D319C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ZAMAN ROZETİ TASARIMI
  Widget _buildZamanRozeti(ReminderModel reminder, Color priorityColor) {
    if ((!reminder.hasDate && !reminder.hasTime) || reminder.scheduledAt == null) {
      return const SizedBox(); // Tarih/Saat yoksa hiçbir şey çizme
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.15), // Karta göre daha belirgin dolgu
        borderRadius: BorderRadius.circular(20), // Kapsül görünümü
        border: Border.all(color: priorityColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_rounded, size: 16, color: priorityColor),
          const SizedBox(width: 6),
          Text(
            _tarihFormatla(reminder.scheduledAt!),
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // GLASSMORPHISM KART TASARIMI
  Widget _buildGlassCard(ReminderModel reminder, Color priorityColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: priorityColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: reminder.isCompleted,
                        activeColor: priorityColor,
                        side: BorderSide(color: priorityColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          _firestoreService.toggleCompletion(reminder.id, reminder.isCompleted);
                          if (!reminder.isCompleted) { // Eğer tamamlandıysa alarmı kapat
                              NotificationService().bildirimIptalEt(reminder.id.hashCode);
                            }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: reminder.isCompleted ? Colors.grey : Colors.white,
                              decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (reminder.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              reminder.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: reminder.isCompleted ? Colors.grey : Colors.white70,
                                decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // ROZETİ VE OLUŞTURULMA TARİHİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Zaman Rozeti
                    _buildZamanRozeti(reminder, priorityColor),

                    // oluşturulma zamanı damgası
                    Text(
                      "Oluşturuldu: ${_tarihFormatla(reminder.createdAt)}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}