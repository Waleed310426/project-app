import 'package:flutter/material.dart';

/// هذه الدالة (`buildTheme`) مسؤولة عن بناء وتكوين الثيم (Theme) الكامل للتطبيق.
/// تأخذ `Brightness` كمدخل (إما `Brightness.dark` أو `Brightness.light`)
/// وتُرجع كائن `ThemeData` مخصصًا بناءً على هذا السطوع.
ThemeData buildTheme(Brightness brightness) {
  // تحديد ما إذا كان الوضع الحالي هو الوضع الداكن.
  final isDark = brightness == Brightness.dark;

  // إرجاع كائن `ThemeData` الذي يحتوي على كل إعدادات التصميم.
  return ThemeData(
    // تفعيل استخدام تصميم Material 3.
    useMaterial3: true,
    // تحديد سطوع الثيم (داكن أو فاتح).
    brightness: brightness,
    // `colorSchemeSeed` هو اللون الأساسي الذي سيتم اشتقاق بقية ألوان التطبيق منه
    // (مثل primary, secondary, tertiary, etc.).
    colorSchemeSeed: const Color(0xFF6366F1), // اللون الأساسي (بنفسجي مائل للأزرق).

    // لون خلفية الشاشات الرئيسية (Scaffold).
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF1A1C20) // خلفية داكنة مخصصة.
        : const Color(0xFFF8F9FA), // خلفية فاتحة مخصصة (أبيض مائل للرمادي).

    // تحديد الخط الافتراضي للتطبيق بأكمله.
    fontFamily: 'Tajawal',

    // تخصيص تصميم الشريط العلوي (AppBar).
    appBarTheme: AppBarTheme(
      elevation: 0, // إزالة الظل تحت الشريط العلوي.
      centerTitle: true, // توسيط العنوان.
      backgroundColor: isDark // لون خلفية الشريط العلوي.
          ? const Color(0xFF1A1C20) // نفس لون خلفية الشاشة في الوضع الداكن.
          : const Color(0xFFF8F9FA), // نفس لون خلفية الشاشة في الوضع الفاتح.
      titleTextStyle: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black, // لون نص العنوان.
      ),
    ),

    // تخصيص تصميم حقول الإدخال (TextFormField, TextField).
    inputDecorationTheme: InputDecorationTheme(
      filled: true, // تفعيل الخلفية الملونة للحقل.
      fillColor: isDark ? const Color(0xFF2A2C30) : Colors.grey[200], // لون الخلفية.
      // تحديد شكل الحدود (بدون خط خارجي وبزوايا دائرية).
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      // تخصيص نمط النص الذي يظهر فوق الحقل (Label).
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    ),
  );
}
