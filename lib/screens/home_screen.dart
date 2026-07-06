import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/reminder_model.dart';
import 'login_screen.dart';
import 'add_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Tarih damgası
  String _tarihFormatla(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Çıkış fonksiyonu
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
      extendBodyBehindAppBar: true, // Appbar'ın arkasını da degrade yap
      appBar: AppBar(
        title: const Text("Hatırlatıcılarım", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      // Glass-Card
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<ReminderModel>>(
            stream: _firestoreService.getReminders(), // Veritabanını canlı dinle
            builder: (context, snapshot) {
              // Yükleniyor durumu
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              // Hata durumu
              if (snapshot.hasError) {
                return Center(child: Text("Bir hata oluştu: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final reminders = snapshot.data ?? [];

              // Liste boşsa
              if (reminders.isEmpty) {
                return const Center(
                  child: Text(
                    "Henüz bir hatırlatıcı eklemedin.\nHadi bir tane oluştur!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              // Liste görünümü
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];

                  // Priority e göre renk
                  Color priorityColor;
                  if (reminder.priority == 2) {
                    priorityColor = Colors.redAccent; // Yüksek
                  } else if (reminder.priority == 1) {
                    priorityColor = Colors.orangeAccent; // Orta
                  } else {
                    priorityColor = Colors.lightBlueAccent; // Düşük
                  }

                  // Done durumunda soluk (inactive) görünüm
                  if (reminder.isCompleted) {
                    priorityColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildGlassCard(reminder, priorityColor),
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
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Glass-card
  Widget _buildGlassCard(ReminderModel reminder, Color priorityColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Kartın köşelerini yuvarlat
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Cam bulanıklığı
        child: Container(
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.15), // İçi hafif saydam renkli
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: priorityColor.withOpacity(0.4), // Kenarlık biraz daha belirgin
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
                    // Done checkbox
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: reminder.isCompleted,
                        activeColor: priorityColor,
                        side: BorderSide(color: priorityColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          // Firestore'daki durumu anında güncelle
                          _firestoreService.toggleCompletion(reminder.id, reminder.isCompleted);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Başlık ve detay
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
                              // Tamamlandıysa üstünü çiz
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
                
                const SizedBox(height: 12),

                // Planlanan zaman ve oluşturma tarihi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Planlanan Zaman (Eğer tarih veya saat seçilmişse göster)
                    (reminder.hasDate || reminder.hasTime) && reminder.scheduledAt != null
                        ? Row(
                            children: [
                              Icon(Icons.access_time_filled, size: 16, color: priorityColor),
                              const SizedBox(width: 4),
                              Text(
                                _tarihFormatla(reminder.scheduledAt!),
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(), // Tarih seçilmemişse boş bırak

                    // Reminder zaman damgası
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