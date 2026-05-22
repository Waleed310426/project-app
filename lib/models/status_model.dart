// lib/models/status_model.dart

/// هذا الكلاس (Model) يمثل حالة عامة يمكن استخدامها للمشاريع أو المهام.
/// على سبيل المثال: "نشط"، "مكتمل"، "في الانتظار"، "متأخر".
/// يُستخدم كجدول بحث (lookup table) لتحديد حالة المشاريع والمهام.
class Status {
  // --- خصائص الكلاس ---

  final int id; // المعرف الرقمي الفريد للحالة (مثل: 1 لـ "نشط").
  final String name; // اسم الحالة (مثل: "مكتمل").
  
  /// `color`: اللون المرتبط بالحالة، ويتم تخزينه كنص بصيغة Hex.
  /// مثال: '#4CAF50' للون الأخضر.
  final String color;

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Status`.
  Status({
    required this.id,
    required this.name,
    required this.color,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Status` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      id: map['id'],
      name: map['name'],
      color: map['color'],
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Status` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
