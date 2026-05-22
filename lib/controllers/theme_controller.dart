import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// هذا الكلاس (Controller) مسؤول عن إدارة ثيم (Theme) التطبيق،
/// أي التبديل بين الوضع المظلم (Dark Mode) والوضع الفاتح (Light Mode).
class ThemeController extends ChangeNotifier {
  // `_kKey` هو مفتاح ثابت يُستخدم لحفظ إعداد الثيم في ذاكرة الهاتف.
  static const _kKey = 'taskly_theme_dark';
  
  // `_isDark` هو متغير داخلي لتخزين الحالة الحالية للثيم (هل هو مظلم أم لا).
  bool _isDark = false;

  // دالة `get` بسيطة للوصول إلى قيمة `_isDark` من خارج الكلاس.
  bool get isDark => _isDark;

  /// دالة `load`: يتم استدعاؤها عند بدء تشغيل التطبيق.
  /// وظيفتها هي قراءة الإعداد المحفوظ مسبقًا للثيم من ذاكرة الهاتف.
  Future<void> load() async {
    // الحصول على نسخة من `SharedPreferences` للوصول إلى الذاكرة المحلية.
    final prefs = await SharedPreferences.getInstance();
    
    // قراءة القيمة المنطقية (true/false) المرتبطة بالمفتاح `_kKey`.
    // إذا لم تكن هناك قيمة محفوظة من قبل (أول مرة يفتح فيها التطبيق)، يتم استخدام `false` كقيمة افتراضية.
    _isDark = prefs.getBool(_kKey) ?? false;
    
    // `notifyListeners()`: إخطار جميع الواجهات التي تستمع لهذا الـ Controller بأن الحالة قد تغيرت،
    // لكي تقوم بتحديث نفسها (تغيير الألوان).
    notifyListeners();
  }

  /// دالة `toggle`: يتم استدعاؤها عند الضغط على زر تغيير الثيم.
  /// وظيفتها هي عكس الحالة الحالية للثيم وحفظ الإعداد الجديد.
  Future<void> toggle() async {
    // عكس القيمة الحالية (إذا كانت `true` تصبح `false` والعكس).
    _isDark = !_isDark;
    
    // إخطار الواجهات بالتغيير فورًا لتوفير استجابة سريعة للمستخدم.
    notifyListeners();
    
    // حفظ القيمة الجديدة في ذاكرة الهاتف لكي يتم تذكرها عند إعادة تشغيل التطبيق.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, _isDark);
  }
}
