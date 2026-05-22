// lib/models/task_model.dart

import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل مهمة واحدة.
/// المهمة هي وحدة العمل الأساسية في التطبيق، ويمكن أن تكون جزءًا من مشروع أو مهمة مستقلة.
class Task {
  // --- الخصائص الأساسية (المخزنة مباشرة في جدول المهام) ---

  final String id; // المعرف الفريد للمهمة.
  final String name; // اسم المهمة.
  final String? description; // وصف تفصيلي للمهمة (اختياري).
  final String? projectId; // معرف المشروع الذي تنتمي إليه المهمة (إن وجد).
  final String? parentTaskId; // معرف المهمة الأم (إذا كانت هذه مهمة فرعية).
  final String ownerId; // معرف المستخدم الذي أنشأ (يملك) المهمة.
  final String? assigneeId; // معرف المستخدم المُكلف بإنجاز المهمة (اختياري).
  final int statusId; // معرف حالة المهمة (نشطة، مكتملة، ...).
  double progress; // نسبة تقدم إنجاز المهمة (من 0.0 إلى 1.0).
  bool isCompleted; // هل تم إنجاز المهمة بالكامل؟
  final DateTime? startDate; // تاريخ بدء المهمة (اختياري).
  final DateTime? endDate; // تاريخ انتهاء المهمة المتوقع (اختياري).
  final double? budget; // الميزانية المخصصة للمهمة (اختياري).
  bool isFavorite; // هل المهمة مميزة (مفضلة)؟
  bool isArchived; // هل تمت أرشفة المهمة؟
  bool isDeleted; // هل تم حذف المهمة (حذف مبدئي)؟
  final DateTime createdAt; // تاريخ ووقت إنشاء المهمة.
  DateTime modifiedAt; // تاريخ ووقت آخر تعديل على المهمة.
  bool isSynced; // هل تمت مزامنة المهمة مع الخادم السحابي؟
  final double totalExpenses; // إجمالي المصروفات المسجلة على هذه المهمة.

  // --- الخصائص المحسوبة (تأتي من استعلامات معقدة وليست مخزنة مباشرة في جدول المهام) ---

  final int subtaskCount; // عدد المهام الفرعية التابعة لهذه المهمة.
  final String? ownerName; // اسم مالك المهمة (يتم جلبه من جدول المستخدمين).
  final String? assigneeName; // اسم الشخص المُكلف بالمهمة (يتم جلبه من جدول المستخدمين).

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Task`.
  Task({
    required this.id,
    required this.name,
    this.description,
    this.projectId,
    this.parentTaskId,
    required this.ownerId,
    this.assigneeId,
    required this.statusId,
    required this.progress,
    this.startDate,
    this.endDate,
    this.budget,
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.modifiedAt,
    this.isSynced = false,
    this.isCompleted = false,
    this.totalExpenses = 0.0,
    // إضافة الحقول المحسوبة للمُنشئ بقيم افتراضية.
    this.subtaskCount = 0,
    this.ownerName,
    this.assigneeName,
  });

  // --- دوال التحويل ---

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Task` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  /// **ملاحظة:** هذه الدالة تحفظ فقط الخصائص الأساسية التي تنتمي لجدول المهام.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'projectId': projectId,
      'parentTaskId': parentTaskId,
      'ownerId': ownerId,
      'assigneeId': assigneeId,
      'statusId': statusId,
      'progress': progress,
      'isCompleted': isCompleted ? 1 : 0,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'isFavorite': isFavorite ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'totalExpenses': totalExpenses,
    };
  }

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Task` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      projectId: map['projectId'],
      parentTaskId: map['parentTaskId'],
      ownerId: map['ownerId'] ?? 'default_user', // وضع قيمة افتراضية لتجنب الأخطاء.
      assigneeId: map['assigneeId'],
      statusId: map['statusId'],
      progress: (map['progress'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] == 1,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      budget: map['budget'],
      isFavorite: map['isFavorite'] == 1,
      isArchived: map['isArchived'] == 1,
      isDeleted: map['isDeleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      isSynced: map['isSynced'] == 1,
      totalExpenses: (map['totalExpenses'] ?? 0.0).toDouble(),
      // قراءة الحقول المحسوبة من الخريطة.
      subtaskCount: map['subtaskCount'] ?? 0,
    );
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء مهمة جديدة بمعرف فريد وقيم افتراضية.
  factory Task.createNew({
    required String name,
    required String ownerId,
    required int statusId,
    String? description,
    String? projectId,
    String? parentTaskId,
    String? assigneeId,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double progress = 0.0,
    bool isCompleted = false,
  }) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      name: name,
      ownerId: ownerId,
      statusId: statusId,
      description: description,
      projectId: projectId,
      parentTaskId: parentTaskId,
      assigneeId: assigneeId,
      startDate: startDate,
      endDate: endDate,
      budget: budget,
      progress: progress,
      isCompleted: isCompleted,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// دالة `copyWith`:
  /// تنشئ نسخة جديدة من كائن المهمة مع إمكانية تعديل بعض الخصائص.
  /// مفيدة جدًا في إدارة الحالة (State Management) لضمان عدم تغيير الكائنات الحالية (Immutability).
  Task copyWith({
    String? id,
    String? name,
    // ... (باقي الخصائص)
    int? subtaskCount,
    String? ownerName,
    String? assigneeName,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      ownerId: ownerId ?? this.ownerId,
      assigneeId: assigneeId ?? this.assigneeId,
      statusId: statusId ?? this.statusId,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSynced: isSynced ?? this.isSynced,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      ownerName: ownerName ?? this.ownerName,
      assigneeName: assigneeName ?? this.assigneeName,
    );
  }
}
