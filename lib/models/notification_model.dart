// lib/models/notification_model.dart

/// هذا الكلاس (Model) يمثل إشعارًا واحدًا يتم إرساله للمستخدم.
/// على سبيل المثال: إشعار بمهمة جديدة، أو رسالة جديدة، أو تذكير.
class Notification {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للإشعار.
  final String userId; // معرف المستخدم الذي سيستقبل هذا الإشعار.
  final String title; // عنوان الإشعار (النص الذي يظهر بخط عريض).
  final String body; // محتوى الإشعار (النص التفصيلي).
  final String type; // نوع الإشعار، لتحديد الإجراء عند الضغط عليه (مثال: 'new_task', 'new_message').
  
  /// `referenceId`: معرف الكائن المرتبط بالإشعار (اختياري).
  /// على سبيل المثال، إذا كان الإشعار عن مهمة جديدة، سيكون هذا هو `id` الخاص بتلك المهمة.
  /// يُستخدم للانتقال إلى الشاشة الصحيحة عند الضغط على الإشعار.
  final String? referenceId;
  
  final bool isRead; // هل قام المستخدم بقراءة الإشعار؟
  final DateTime createdAt; // تاريخ ووقت إنشاء الإشعار.

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Notification`.
  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Notification` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      body: map['body'],
      type: map['type'],
      referenceId: map['referenceId'],
      isRead: map['isRead'] == 1, // تحويل 1/0 إلى true/false.
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Notification` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'referenceId': referenceId,
      'isRead': isRead ? 1 : 0, // تحويل true/false إلى 1/0.
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
    };
  }
}
