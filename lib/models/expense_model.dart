// lib/models/expense_model.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة.
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل عملية مصروف واحدة.
/// يمكن ربط المصروف بمشروع معين أو مهمة معينة.
class Expense {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للمصروف.
  final String description; // وصف المصروف (مثال: "وجبة غداء مع العميل").
  final double amount; // مبلغ المصروف.
  final DateTime date; // تاريخ حدوث المصروف.
  final String? projectId; // معرف المشروع الذي يرتبط به المصروف (إن وجد).
  final String? taskId; // معرف المهمة التي يرتبط بها المصروف (إن وجد).
  final String recordedByUserId; // معرف المستخدم الذي قام بتسجيل هذا المصروف.
  final String? receiptUrl; // رابط أو مسار صورة الفاتورة (الإيصال).
  final DateTime createdAt; // تاريخ ووقت تسجيل المصروف في التطبيق.
  final bool isSynced; // هل تمت مزامنة هذا المصروف مع الخادم السحابي؟

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Expense`.
  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.projectId,
    this.taskId,
    required this.recordedByUserId,
    this.receiptUrl,
    required this.createdAt,
    required this.isSynced,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Expense` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']), // تحويل النص إلى تاريخ.
      projectId: map['projectId'],
      taskId: map['taskId'],
      recordedByUserId: map['recordedByUserId'],
      receiptUrl: map['receiptUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1, // تحويل 1/0 إلى true/false.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Expense` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(), // تحويل التاريخ إلى نص بصيغة قياسية.
      'projectId': projectId,
      'taskId': taskId,
      'recordedByUserId': recordedByUserId,
      'receiptUrl': receiptUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0, // تحويل true/false إلى 1/0.
    };
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء مصروف جديد بمعرف فريد وقيم افتراضية.
  /// مفيدة عند إضافة مصروف جديد من قبل المستخدم.
  factory Expense.createNew({
    required String description,
    required double amount,
    required DateTime date,
    required String recordedByUserId,
    String? projectId,
    String? taskId,
    String? receiptUrl,
  }) {
    return Expense(
      id: const Uuid().v4(), // إنشاء ID فريد تلقائيًا.
      description: description,
      amount: amount,
      date: date,
      recordedByUserId: recordedByUserId,
      projectId: projectId,
      taskId: taskId,
      receiptUrl: receiptUrl,
      createdAt: DateTime.now(), // استخدام الوقت الحالي كوقت إنشاء.
      isSynced: false, // القيمة الافتراضية عند الإنشاء.
    );
  }
}
