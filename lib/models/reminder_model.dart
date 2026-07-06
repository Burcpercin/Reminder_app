import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  String id;             
  String userId;         
  String title;          
  String description;    // İsteğe bağlı
  
  bool hasDate;          // Sadece tarih seçici aktif mi?
  bool hasTime;          // Sadece saat seçici aktif mi?
  DateTime? scheduledAt; // Eğer tarih/saat seçildiyse kesinleşmiş nihai zaman
  
  int priority;          // 0 (Düşük), 1 (Orta), 2 (Yüksek)

  bool isCompleted;       
  DateTime createdAt;    // Sıralama için önemli

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.hasDate = false,
    this.hasTime = false,
    this.scheduledAt,
    this.priority = 1,   // Varsayılan olarak 'Orta' öncelik
    this.isCompleted = false,
    required this.createdAt,
  });


  factory ReminderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ReminderModel(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      hasDate: map['hasDate'] ?? false,
      hasTime: map['hasTime'] ?? false,
      // Firestore tarihleri 'Timestamp' olarak tutar, onu normal 'DateTime'a çeviriyoruz
      scheduledAt: map['scheduledAt'] != null ? (map['scheduledAt'] as Timestamp).toDate() : null,
      priority: map['priority'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  // Uygulamamızdaki veriyi internete (Firestore'a) gönderebileceğimiz JSON/Map formatına çevir
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'hasDate': hasDate,
      'hasTime': hasTime,
      // DateTime objelerini tekrar Firestore'un anladığı 'Timestamp' formatına çeviriyoruz
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}