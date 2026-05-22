// lib/models/daily_task_model.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة.
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل مهمة يومية واحدة.
/// يختلف عن المهام العادية (Task) بأنه مصمم للمهام السريعة أو الروتينية
/// التي يتم جدولتها وتنفيذها في يوم محدد.
class DailyTask {
  // --- خصائص الكلاس ---

  String id; // المعرف الفريد للمهمة.
  String name; // اسم المهمة (العنوان).
  String? description; // وصف تفصيلي للمهمة (اختياري).
  DateTime? startTime; // وقت بدء المهمة (اختياري).
  DateTime? endTime; // وقت انتهاء المهمة (اختياري).
  double? budget; // الميزانية المخصصة للمهمة (اختياري).
  bool isCompleted; // هل تم إنجاز المهمة؟
  bool isFavorite; // هل المهمة مميزة (مفضلة)؟
  bool isArchived; // هل تمت أرشفة المهمة؟
  bool isDeleted; // هل تم حذف المهمة (حذف مبدئي)؟
  DateTime createdAt; // تاريخ ووقت إنشاء المهمة.
  DateTime modifiedAt; // تاريخ ووقت آخر تعديل على المهمة.
  String ownerId; // معرف المستخدم الذي يملك هذه المهمة.

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `DailyTask`.
  DailyTask({
    required this.id,
    required this.name,
    this.description,
    this.startTime,
    this.endTime,
    this.budget,
    this.isCompleted = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.modifiedAt,
    required this.ownerId,
  });

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء مهمة يومية جديدة بمعرف فريد وقيم افتراضية.
  factory DailyTask.createNew({
    required String name,
    required String ownerId,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    double? budget,
  }) {
    final now = DateTime.now(); // الحصول على الوقت الحالي.
    return DailyTask(
      id: const Uuid().v4(), // إنشاء ID فريد تلقائيًا.
      name: name,
      ownerId: ownerId,
      description: description,
      startTime: startTime,
      endTime: endTime,
      budget: budget,
      isCompleted: false, // القيمة الافتراضية عند الإنشاء.
      isFavorite: false,
      isArchived: false,
      isDeleted: false,
      createdAt: now, // تعيين وقت الإنشاء.
      modifiedAt: now, // تعيين وقت التعديل الأخير.
    );
  }

  // --- دوال التحويل ---

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `DailyTask` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      // تحويل التاريخ إلى نص بصيغة ISO 8601 القياسية إذا لم يكن فارغًا.
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'budget': budget,
      // تحويل القيم المنطقية (true/false) إلى أرقام (1/0) لأن SQLite يفضلها.
      'isCompleted': isCompleted ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'ownerId': ownerId,
    };
  }

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `DailyTask` من خريطة (Map) قادمة من قاعدة البيانات.
  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      // تحويل النص إلى تاريخ إذا لم يكن فارغًا.
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      budget: map['budget'],
      // تحويل الأرقام (1/0) مرة أخرى إلى قيم منطقية (true/false).
      isCompleted: map['isCompleted'] == 1,
      isFavorite: map['isFavorite'] == 1,
      isArchived: map['isArchived'] == 1,
      isDeleted: map['isDeleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      ownerId: map['ownerId'],
    );
  }
}
