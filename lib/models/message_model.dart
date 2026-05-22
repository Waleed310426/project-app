// lib/models/message_model.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة.
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل رسالة واحدة في نظام الدردشة الخاص بالمشاريع أو المهام.
class Message {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للرسالة.
  final String? content; // المحتوى النصي للرسالة (يمكن أن يكون فارغًا إذا كانت الرسالة مجرد مرفق).
  final String senderId; // معرف المستخدم الذي أرسل الرسالة.
  final String? projectId; // معرف المشروع الذي أُرسلت فيه الرسالة (إن وجد).
  final String? taskId; // معرف المهمة التي أُرسلت فيها الرسالة (إن وجد).
  final DateTime createdAt; // تاريخ ووقت إرسال الرسالة.
  final bool isDeletedForSender; // هل قام المرسل بحذف الرسالة من طرفه؟
  final String? attachmentUrl; // رابط أو مسار الملف المرفق مع الرسالة (إن وجد).
  final String? attachmentType; // نوع المرفق (مثل: 'image', 'pdf').

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Message`.
  Message({
    required this.id,
    this.content,
    required this.senderId,
    this.projectId,
    this.taskId,
    required this.createdAt,
    this.isDeletedForSender = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Message` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      senderId: map['senderId'],
      projectId: map['projectId'],
      taskId: map['taskId'],
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
      isDeletedForSender: map['isDeletedForSender'] == 1, // تحويل 1/0 إلى true/false.
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Message` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'projectId': projectId,
      'taskId': taskId,
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
      'isDeletedForSender': isDeletedForSender ? 1 : 0, // تحويل true/false إلى 1/0.
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
    };
  }
  
  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء رسالة جديدة بمعرف فريد ووقت إنشاء حالي.
  /// مفيدة عند إرسال رسالة جديدة من قبل المستخدم.
  factory Message.createNew({
    String? content,
    required String senderId,
    String? projectId,
    String? taskId,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return Message(
      id: const Uuid().v4(), // إنشاء ID فريد تلقائيًا.
      content: content,
      senderId: senderId,
      projectId: projectId,
      taskId: taskId,
      createdAt: DateTime.now(), // استخدام الوقت الحالي كوقت إرسال.
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
  }
}
