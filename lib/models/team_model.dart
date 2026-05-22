// lib/models/team_model.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة.
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل فريق عمل واحد.
/// الفريق هو مجموعة من المستخدمين الذين يعملون معًا على المشاريع.
class Team {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للفريق.
  final String name; // اسم الفريق.
  final String? description; // وصف تفصيلي للفريق (اختياري).
  final String? avatarUrl; // رابط الصورة الرمزية للفريق (اختياري).
  final String ownerId; // معرف المستخدم الذي أنشأ (يملك) الفريق.
  final DateTime createdAt; // تاريخ ووقت إنشاء الفريق.
  final DateTime modifiedAt; // تاريخ ووقت آخر تعديل على الفريق.
  final bool isSynced; // هل تمت مزامنة بيانات الفريق مع الخادم السحابي؟

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Team`.
  Team({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.createdAt,
    required this.modifiedAt,
    required this.isSynced,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Team` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      avatarUrl: map['avatarUrl'],
      ownerId: map['ownerId'],
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
      modifiedAt: DateTime.parse(map['modifiedAt']),
      isSynced: map['isSynced'] == 1, // تحويل 1/0 إلى true/false.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Team` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
      'modifiedAt': modifiedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0, // تحويل true/false إلى 1/0.
    };
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء فريق جديد بمعرف فريد وقيم افتراضية.
  /// مفيدة عند إنشاء فريق جديد من قبل المستخدم.
  factory Team.createNew({
    required String name,
    required String ownerId,
    String? description,
    String? avatarUrl,
  }) {
    final now = DateTime.now();
    return Team(
      id: const Uuid().v4(), // إنشاء ID فريد تلقائيًا.
      name: name,
      ownerId: ownerId,
      description: description,
      avatarUrl: avatarUrl,
      createdAt: now, // استخدام الوقت الحالي كوقت إنشاء.
      modifiedAt: now, // استخدام الوقت الحالي كوقت آخر تعديل.
      isSynced: false, // القيمة الافتراضية عند الإنشاء.
    );
  }
}
