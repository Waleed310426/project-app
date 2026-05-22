// lib/models/relationship_status_model.dart

/// هذا الكلاس (Model) يمثل حالة العلاقة بين مستخدمين اثنين.
/// على سبيل المثال: "صديق"، "طلب معلق"، "محظور".
/// يُستخدم كجدول بحث (lookup table) لتحديد نوع العلاقة في جدول `user_relationships`.
class RelationshipStatus {
  // --- خصائص الكلاس ---

  final int id; // المعرف الرقمي الفريد للحالة (مثل: 1 لـ "صديق").
  final String name; // اسم الحالة (مثل: "صديق").
  final String? description; // وصف تفصيلي للحالة (اختياري).

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `RelationshipStatus`.
  RelationshipStatus({
    required this.id,
    required this.name,
    this.description,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `RelationshipStatus` من خريطة (Map) قادمة من قاعدة البيانات.
  factory RelationshipStatus.fromMap(Map<String, dynamic> map) {
    return RelationshipStatus(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `RelationshipStatus` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
