// lib/models/app_setting_model.dart

/// هذا الكلاس (Model) يمثل إعدادًا واحدًا من إعدادات التطبيق الخاصة بمستخدم معين.
/// يُستخدم لتخزين أزواج من (مفتاح: قيمة)، مثل ('theme': 'dark') أو ('language': 'ar').
class AppSetting {
  // --- خصائص الكلاس ---

  /// `userId`: معرف المستخدم الذي يملك هذا الإعداد.
  /// يضمن أن إعدادات كل مستخدم منفصلة عن الآخرين.
  final String userId;

  /// `settingKey`: مفتاح الإعداد (اسمه الفريد).
  /// على سبيل المثال: "theme", "notifications_enabled", "default_view".
  final String settingKey;

  /// `settingValue`: قيمة الإعداد.
  /// على سبيل المثال: "dark", "true", "calendar".
  final String settingValue;

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `AppSetting` جديد.
  AppSetting({
    required this.userId,
    required this.settingKey,
    required this.settingValue,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `AppSetting` من خريطة (Map) قادمة من قاعدة البيانات.
  factory AppSetting.fromMap(Map<String, dynamic> map) {
    return AppSetting(
      userId: map['userId'],
      settingKey: map['settingKey'],
      settingValue: map['settingValue'],
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `AppSetting` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'settingKey': settingKey,
      'settingValue': settingValue,
    };
  }
}
