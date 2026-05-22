// lib/models/team_member_model.dart

/// هذا الكلاس (Model) يمثل العلاقة بين فريق ومستخدم، ويحدد دور هذا المستخدم داخل الفريق.
/// يُستخدم كجدول وسيط (junction table) لربط جدول الفرق (teams) بجدول المستخدمين (users).
class TeamMember {
  // --- خصائص الكلاس ---

  final String teamId; // معرف الفريق الذي ينتمي إليه العضو.
  final String userId; // معرف المستخدم (العضو).
  
  /// `role`: دور العضو داخل الفريق.
  /// أمثلة: "قائد", "عضو", "مشرف".
  final String role;
  
  final DateTime joinedAt; // تاريخ ووقت انضمام العضو للفريق.

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `TeamMember`.
  TeamMember({
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `TeamMember` من خريطة (Map) قادمة من قاعدة البيانات.
  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      teamId: map['teamId'],
      userId: map['userId'],
      role: map['role'],
      joinedAt: DateTime.parse(map['joinedAt']), // تحويل النص إلى تاريخ.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `TeamMember` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'userId': userId,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
    };
  }
}
