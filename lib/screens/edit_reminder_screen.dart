import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../models/reminder_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final ReminderModel reminder; 

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final FirestoreService _firestoreService = FirestoreService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'Orta';
  final List<String> _priorityLevels = ['Düşük', 'Orta', 'Yüksek'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descController = TextEditingController(text: widget.reminder.description);
    
    if (widget.reminder.scheduledAt != null) {
      _selectedDate = widget.reminder.scheduledAt;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder.scheduledAt!);
    }
    
    // DÜZELTME 1: Senin modelindeki 0, 1, 2 mantığına göre eşleştirme
    int mevcutOncelik = widget.reminder.priority; 
    if (mevcutOncelik == 0) {
      _selectedPriority = 'Düşük';
    } else if (mevcutOncelik == 2) {
      _selectedPriority = 'Yüksek';
    } else {
      _selectedPriority = 'Orta'; // 1 ise veya hatalıysa Orta olsun
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

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

  Future<void> _guncelle() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başlık boş bırakılamaz."), backgroundColor: Colors.orange),
      );
      return;
    }

    DateTime? finalScheduledAt;
    if (_selectedDate != null && _selectedTime != null) {
      finalScheduledAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    try {
      widget.reminder.title = title;
      widget.reminder.description = description;
      widget.reminder.scheduledAt = finalScheduledAt; 
      
      // Modelindeki hasDate ve hasTime değerlerini de güncelleyelim
      widget.reminder.hasDate = _selectedDate != null;
      widget.reminder.hasTime = _selectedTime != null;
      
      // Seçilen metni tekrar senin modelindeki 0, 1, 2 sistemine çevirme
      int yeniOncelik = 1; // Varsayılan Orta (1)
      if (_selectedPriority == 'Düşük') yeniOncelik = 0;
      else if (_selectedPriority == 'Yüksek') yeniOncelik = 2;
      
      widget.reminder.priority = yeniOncelik; 

      await _firestoreService.updateReminder(widget.reminder);

      if (finalScheduledAt != null && finalScheduledAt.isAfter(DateTime.now())) {
        await NotificationService().bildirimIptalEt(widget.reminder.id.hashCode);
        
        await NotificationService().bildirimKur(
          id: widget.reminder.id.hashCode,
          baslik: title,
          icerik: description.isEmpty ? "Hatırlatıcı zamanı geldi!" : description,
          zaman: finalScheduledAt,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hatırlatıcı başarıyla güncellendi!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme başarısız oldu: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hatırlatıcıyı Düzenle"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Başlık",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: "Açıklama",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _tarihSec(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null
                        ? "Tarih Seç"
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saatSec(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null
                        ? "Saat Seç"
                        : _selectedTime!.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                labelText: "Öncelik Durumu",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.flag),
              ),
              items: _priorityLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPriority = newValue!;
                });
              },
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
                onPressed: _guncelle,
                child: const Text("Değişiklikleri Kaydet", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}