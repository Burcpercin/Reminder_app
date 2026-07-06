import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reminder_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _remindersRef => _db.collection('reminders');

  // Güvenlik: İşlem yapan anlık kullanıcının ID'sini almak için
  String? get currentUserId => _auth.currentUser?.uid;

  // 1. YENİ HATIRLATICI EKLEME (Create)
  Future<void> addReminder(ReminderModel reminder) async {
    if (currentUserId == null) return;
    
    // Güvenlik Duvarı: Veritabanına gidecek verinin ID'si kesinlikle anlık kullanıcıya ait olmalı
    reminder.userId = currentUserId!;
    
    // Modelimizi toMap() ile JSON'a çevirip buluta yolluyoruz
    await _remindersRef.add(reminder.toMap());
  }

  // 2. HATIRLATICILARI OKUMA (Read - Gerçek Zamanlı Dinleme)
  Stream<List<ReminderModel>> getReminders() {
    if (currentUserId == null) return const Stream.empty();

    return _remindersRef
        .where('userId', isEqualTo: currentUserId) // SADECE GİRİŞ YAPAN KULLANICININ NOTLARI
        .orderBy('isCompleted', descending: false) // Tamamlanmamışlar (false) üstte dursun
        .orderBy('priority', descending: true)     // Önceliği yüksek (2) olanlar üstte
        .orderBy('createdAt', descending: true)    // Aynı öncelikteyse en yeni eklenen üstte
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // 3. HATIRLATICI GÜNCELLEME (Update)
  Future<void> updateReminder(ReminderModel reminder) async {
    if (currentUserId == null) return;
    await _remindersRef.doc(reminder.id).update(reminder.toMap());
  }

  // 4. HATIRLATICI SİLME (Delete)
  Future<void> deleteReminder(String reminderId) async {
    if (currentUserId == null) return;
    await _remindersRef.doc(reminderId).delete();
  }

  // 5. CHECKBOX DURUMUNU HIZLI DEĞİŞTİRME (Tamamlandı / Geri Al)
  Future<void> toggleCompletion(String reminderId, bool currentStatus) async {
    if (currentUserId == null) return;
    await _remindersRef.doc(reminderId).update({'isCompleted': !currentStatus});
  }
}