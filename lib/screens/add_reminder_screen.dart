import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/firestore_service.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  // Switch (Slider) Durumları
  bool _hasDate = false;
  bool _hasTime = false;

  // Seçilen Değerler
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  // Öncelik Durumu (0: Düşük, 1: Orta, 2: Yüksek)
  int _priority = 1; 

  // TARİH SEÇİCİ
  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Geçmiş tarihe not alınamaz
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // SAAT SEÇİCİ
  Future<void> _saatSec(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // KAYDETME ALGORİTMASI
  void _kaydet() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir başlık girin!")),
      );
      return;
    }

    DateTime? finalScheduledAt;

    // KULLANICININ ZAMAN MANTIĞI VE EDGE CASE KONTROLLERİ
    if (_hasDate && _hasTime && _selectedDate != null && _selectedTime != null) {
      // 1. İkisi de seçiliyse birleştir
      finalScheduledAt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );
    } else if (_hasDate && !_hasTime && _selectedDate != null) {
      // 2. Sadece Tarih seçiliyse saati 00:00 yap
      finalScheduledAt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0);
    } else if (!_hasDate && _hasTime && _selectedTime != null) {
      // 3. Sadece Saat seçiliyse bugünü baz al
      final now = DateTime.now();
      var calculated = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);
      
      // EDGE CASE: Eğer saat bugünün geçmiş bir saatiyse, tarihi yarına at (Time Travel engellemesi)
      if (calculated.isBefore(now)) {
        calculated = calculated.add(const Duration(days: 1));
      }
      finalScheduledAt = calculated;
    }

    // Yeni Modelimizi oluşturuyoruz
    final newReminder = ReminderModel(
      id: '', // Firestore oluştururken kendi ID verecek, biz boş geçiyoruz
      userId: '', // Servis katmanında otomatik eklenecek
      title: title,
      description: _descController.text.trim(),
      hasDate: _hasDate,
      hasTime: _hasTime,
      scheduledAt: finalScheduledAt,
      priority: _priority,
      createdAt: DateTime.now(),
    );

    // Veritabanına gönder ve ekranı kapat
    await _firestoreService.addReminder(newReminder);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Hatırlatıcı"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView( // Klavye açıldığında ekranın taşmasını engeller
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK VE NOT KISMI
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Başlık (Zorunlu)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Detay / Not", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // ÖNCELİK SEÇİMİ (Segmented Control tarzı)
            const Text("Öncelik Seviyesi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text("Düşük"),
                  selected: _priority == 0,
                  onSelected: (val) => setState(() => _priority = 0),
                  selectedColor: Colors.blue.shade200,
                ),
                ChoiceChip(
                  label: const Text("Orta"),
                  selected: _priority == 1,
                  onSelected: (val) => setState(() => _priority = 1),
                  selectedColor: Colors.orange.shade200,
                ),
                ChoiceChip(
                  label: const Text("Yüksek"),
                  selected: _priority == 2,
                  onSelected: (val) => setState(() => _priority = 2),
                  selectedColor: Colors.red.shade200,
                ),
              ],
            ),
            const Divider(height: 40),

            // TARİH SEÇİCİ SLIDER (Açılır/Kapanır)
            SwitchListTile(
              title: const Text("Tarih Ekle"),
              value: _hasDate,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (val) {
                setState(() {
                  _hasDate = val;
                  if (val && _selectedDate == null) _selectedDate = DateTime.now(); // Açıldığında bugünü varsayılan yap
                });
              },
            ),
            if (_hasDate) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedDate != null 
                        ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" 
                        : "Tarih Seçilmedi"),
                    TextButton(onPressed: () => _tarihSec(context), child: const Text("Tarih Seç")),
                  ],
                ),
              ),
            ],

            const Divider(),

            // SAAT SEÇİCİ SLIDER (Açılır/Kapanır)
            SwitchListTile(
              title: const Text("Saat Ekle"),
              value: _hasTime,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (val) {
                setState(() {
                  _hasTime = val;
                  if (val && _selectedTime == null) _selectedTime = TimeOfDay.now();
                });
              },
            ),
            if (_hasTime) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime != null 
                        ? _selectedTime!.format(context) 
                        : "Saat Seçilmedi"),
                    TextButton(onPressed: () => _saatSec(context), child: const Text("Saat Seç")),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                onPressed: _kaydet,
                child: const Text("Hatırlatıcıyı Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}