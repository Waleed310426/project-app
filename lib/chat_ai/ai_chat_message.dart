// lib/chat_ai/ai_chat_message.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة للرسائل.
import 'package.uuid/uuid.dart';

/// هذا الكلاس يمثل هيكل رسالة الدردشة الواحدة.
/// كل كائن (object) من هذا الكلاس هو عبارة عن رسالة.
class AiChatMessage {
  // --- الخصائص الأساسية للرسالة ---

  final String id; // معرف فريد للرسالة.
  final String conversationId; // يحدد إلى أي محادثة تنتمي هذه الرسالة.
  final String content; // النص الفعلي للرسالة.
  final bool isFromUser; // `true` لو كانت من المستخدم، و `false` لو من الذكاء الاصطناعي.
  final DateTime createdAt; // وقت إرسال الرسالة.

  // --- المُنشئ (Constructor) ---

  /// عند إنشاء رسالة جديدة، يتم استدعاء هذا الكود.
  AiChatMessage({
    String? id,
    required this.conversationId,
    required this.content,
    required this.isFromUser,
    DateTime? createdAt,
  })  // إذا لم يتم توفير `id`، يتم إنشاء واحد جديد تلقائيًا.
        : id = id ?? const Uuid().v4(),
        // إذا لم يتم توفير وقت، يتم استخدام الوقت الحالي.
        createdAt = createdAt ?? DateTime.now();

  // --- دوال التحويل ---

  /// تحويل بيانات الرسالة إلى صيغة `Map` (خريطة) لحفظها في قاعدة البيانات.
  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'content': content,
        'isFromUser': isFromUser ? 1 : 0, // تحويل `true/false` إلى `1/0`.
        'createdAt': createdAt.millisecondsSinceEpoch, // تحويل التاريخ إلى رقم.
      };

  /// إنشاء رسالة جديدة من بيانات محفوظة بصيغة `Map` (قادمة من قاعدة البيانات).
  factory AiChatMessage.fromMap(Map<String, dynamic> map) => AiChatMessage(
        id: map['id'],
        conversationId: map['conversationId'],
        content: map['content'],
        isFromUser: map['isFromUser'] == 1, // تحويل `1/0` مرة أخرى إلى `true/false`.
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']), // تحويل الرقم إلى تاريخ.
      );
}
