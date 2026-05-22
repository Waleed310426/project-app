// lib/models/user_relationship_model.dart

/// هذا الكلاس (Model) يمثل العلاقة بين مستخدمين اثنين.
/// يُستخدم كجدول وسيط (junction table) لتسجيل العلاقات الاجتماعية في التطبيق،
/// مثل الصداقات، طلبات الصداقة، أو الحظر.
class UserRelationship {
  // --- خصائص الكلاس ---

  /// `userOneId`: معرف المستخدم الأول في العلاقة.
  final String userOneId;

  /// `userTwoId`: معرف المستخدم الثاني في العلاقة.
  final String userTwoId;

  /// `statusId`: معرف حالة العلاقة (يأتي من جدول `relationship_statuses`).
  /// يحدد نوع العلاقة (مثال: 1 لـ "صديق"، 2 لـ "طلب معلق").
  final int statusId;

  /// `createdAt`: تاريخ ووقت إنشاء هذه العلاقة.
  final DateTime createdAt;

  /// `modifiedAt`: تاريخ ووقت آخر تعديل على حالة هذه العلاقة.
  final DateTime modifiedAt;

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `UserRelationship`.
  UserRelationship({
    required this.userOneId,
    required this.userTwoId,
    required this.statusId,
    required this.createdAt,
    required this.modifiedAt,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `UserRelationship` من خريطة (Map) قادمة من قاعدة البيانات.
  factory UserRelationship.fromMap(Map<String, dynamic> map) {
    return UserRelationship(
      userOneId: map['userOneId'],
      userTwoId: map['userTwoId'],
      statusId: map['statusId'],
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
      modifiedAt: DateTime.parse(map['modifiedAt']),
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `UserRelationship` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'userOneId': userOneId,
      'userTwoId': userTwoId,
      'statusId': statusId,
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }
}
