// lib/models/user_model.dart

// استيراد مكتبة Firebase Authentication مع استخدام اسم مستعار (alias) `firebase`
// لتجنب أي تعارض في الأسماء مع كلاس `User` الخاص بنا.
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// هذا الكلاس (Model) يمثل بيانات المستخدم في تطبيقنا.
/// يتم فصله عن كائن المستخدم الخاص بـ Firebase ليكون لدينا تحكم كامل في البيانات.
class User {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للمستخدم (يأتي من Firebase Auth UID).
  final String? name; // اسم المستخدم.
  final String? email; // البريد الإلكتروني للمستخدم.
  final String? phoneNumber; // رقم هاتف المستخدم.
  final String? avatarUrl; // رابط الصورة الرمزية للمستخدم.
  final DateTime createdAt; // تاريخ ووقت إنشاء حساب المستخدم.
  DateTime? lastLogin; // تاريخ ووقت آخر تسجيل دخول للمستخدم.

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `User`.
  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.createdAt,
    this.lastLogin,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromFirebase`:
  /// تقوم بتحويل كائن المستخدم القادم من `firebase.User` إلى كائن `User` الخاص بتطبيقنا.
  /// هذه الدالة مهمة جدًا لتوحيد نموذج المستخدم بعد عملية تسجيل الدخول أو إنشاء الحساب.
  factory User.fromFirebase(firebase.User firebaseUser) {
    return User(
      id: firebaseUser.uid, // استخدام `uid` كمعرف فريد.
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      // استخدام تاريخ إنشاء الحساب من بيانات Firebase، مع توفير قيمة افتراضية (الوقت الحالي) إذا كانت غير موجودة.
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLogin: firebaseUser.metadata.lastSignInTime,
    );
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء كائن مستخدم جديد بقيم محددة ووقت إنشاء حالي.
  /// مفيدة عند إنشاء مستخدم جديد يدويًا أو قبل حفظه في قاعدة البيانات لأول مرة.
  factory User.createNew({
    required String id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(), // استخدام الوقت الحالي كوقت إنشاء.
      lastLogin: DateTime.now(), // استخدام الوقت الحالي كآخر تسجيل دخول.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `User` إلى خريطة (Map) لحفظه في قاعدة البيانات (المحلية أو السحابية).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `User` من خريطة (Map) قادمة من قاعدة البيانات المحلية (SQLite).
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
      // التحقق من أن `lastLogin` ليس فارغًا قبل تحويله.
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }
}
