// lib/models/expense_category_model.dart

import 'package:flutter/material.dart';

/// هذا الكلاس (Model) يمثل فئة أو تصنيفًا للمصروفات.
/// على سبيل المثال: "طعام"، "مواصلات"، "فواتير".
/// يُستخدم لتنظيم وتصنيف المصروفات المختلفة.
class ExpenseCategory {
  // --- خصائص الكلاس ---

  final int id; // المعرف الرقمي الفريد للفئة.
  final String name; // اسم الفئة (مثل: "سفر").
  final IconData icon; // الأيقونة التي تمثل الفئة.
  final Color color; // اللون المميز للفئة.

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `ExpenseCategory`.
  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `ExpenseCategory` من خريطة (Map) قادمة من قاعدة البيانات.
  /// هذه الدالة تحتوي على منطق خاص لتحويل البيانات المخزنة إلى أنواع يفهمها Flutter.
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],

      // تحويل `iconCodePoint` (وهو رقم مخزن في قاعدة البيانات) إلى كائن `IconData` يمكن عرضه في الواجهة.
      // `fontFamily: 'MaterialIcons'` ضروري ليعرف Flutter من أي مجموعة أيقونات سيتم جلب هذه الأيقونة.
      icon: IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons'),

      // تحويل `color` (وهو نص مخزن بصيغة Hex مثل "#FF5733") إلى كائن `Color` يمكن استخدامه في Flutter.
      // 1. `map['color'].substring(1, 7)`: يزيل علامة '#' ويأخذ الستة أرقام التالية.
      // 2. `int.parse(..., radix: 16)`: يحول النص السداسي عشري إلى رقم صحيح.
      // 3. `+ 0xFF000000`: يضيف قيمة الشفافية (ألفا) للون لجعله غير شفاف تمامًا.
      color: Color(int.parse(map['color'].substring(1, 7), radix: 16) + 0xFF000000),
    );
  }
}
