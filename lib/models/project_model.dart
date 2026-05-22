// lib/models/project_model.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل مشروعًا واحدًا.
/// المشروع هو حاوية رئيسية للمهام والمصروفات والرسائل.
class Project {
  // --- الخصائص الأساسية (المخزنة مباشرة في جدول المشاريع) ---

  final String id; // المعرف الفريد للمشروع.
  final String name; // اسم المشروع.
  final String? description; // وصف تفصيلي للمشروع (اختياري).
  final DateTime startDate; // تاريخ بدء المشروع.
  final DateTime endDate; // تاريخ انتهاء المشروع المتوقع.
  final int statusId; // معرف حالة المشروع (نشط، مكتمل، متأخر...).
  final double? budget; // الميزانية المخصصة للمشروع (اختياري).
  final String? imageUrl; // رابط صورة غلاف المشروع (اختياري).
  final String? teamId; // معرف الفريق المسؤول عن المشروع (اختياري).
  final String ownerId; // معرف المستخدم مالك المشروع.
  bool isDeleted; // هل تم حذف المشروع (حذف مبدئي)؟
  bool isArchived; // هل تمت أرشفة المشروع؟
  bool isFavorite; // هل المشروع مميز (مفضل)؟
  final DateTime createdAt; // تاريخ ووقت إنشاء المشروع.
  DateTime modifiedAt; // تاريخ ووقت آخر تعديل على المشروع.
  bool isSynced; // هل تمت مزامنة المشروع مع الخادم السحابي؟
  String? color; // لون مميز للمشروع (يُستخدم في الواجهة).
  final double totalExpenses; // إجمالي المصروفات المسجلة على المشروع (يتم تحديثه).

  // --- الخصائص المحسوبة (تأتي من استعلامات معقدة `JOIN` وليست مخزنة مباشرة في جدول المشاريع) ---

  final int taskCount; // عدد المهام الإجمالي في المشروع.
  final double progress; // متوسط تقدم جميع المهام في المشروع (من 0.0 إلى 1.0).
  final String? ownerName; // اسم مالك المشروع (يتم جلبه من جدول المستخدمين).

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Project`.
  Project({
    required this.id,
    required this.name,
    required this.statusId,
    this.description,
    required this.startDate,
    required this.endDate,
    this.budget,
    this.imageUrl,
    this.teamId,
    required this.ownerId,
    this.isDeleted = false,
    this.isArchived = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.modifiedAt,
    this.isSynced = false,
    // إضافة الحقول الجديدة للمُنشئ
    this.color,
    this.totalExpenses = 0.0,
    // إضافة الحقول المحسوبة
    this.taskCount = 0,
    this.progress = 0.0,
    this.ownerName,
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Project` من خريطة (Map) قادمة من قاعدة البيانات.
  /// هذه الخريطة قد تحتوي على بيانات من جداول متعددة بفضل استعلامات `JOIN`.
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      statusId: map['statusId'],
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      budget: map['budget'],
      imageUrl: map['imageUrl'],
      teamId: map['teamId'],
      ownerId: map['ownerId'],
      isDeleted: map['isDeleted'] == 1,
      isArchived: map['isArchived'] == 1,
      isFavorite: map['isFavorite'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      isSynced: map['isSynced'] == 1,
      // قراءة الحقول الجديدة
      color: map['color'],
      totalExpenses: (map['totalExpenses'] ?? 0.0).toDouble(),
      // قراءة الحقول المحسوبة من الخريطة
      taskCount: map['taskCount'] ?? 0,
      progress: (map['avgProgress'] ?? 0.0).toDouble(), // `avgProgress` هو الاسم المستعار في استعلام SQL.
      ownerName: map['ownerName'],
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Project` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  /// **ملاحظة:** هذه الدالة تحفظ فقط الخصائص الأساسية التي تنتمي لجدول المشاريع.
  /// الخصائص المحسوبة (مثل `taskCount`, `progress`) لا يتم حفظها هنا لأنها تُحسب عند القراءة.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'statusId': statusId,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'imageUrl': imageUrl,
      'teamId': teamId,
      'ownerId': ownerId,
      'isDeleted': isDeleted ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      // الحقول الجديدة
      'color': color,
      'totalExpenses': totalExpenses,
    };
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء مشروع جديد بمعرف فريد وقيم افتراضية.
  factory Project.createNew({
    required String name,
    required int statusId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
    double? budget,
    String? imageUrl,
    String? teamId,
    String? color,
  }) {
    final now = DateTime.now();
    return Project(
      id: const Uuid().v4(),
      name: name,
      statusId: statusId,
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      description: description,
      budget: budget,
      imageUrl: imageUrl,
      teamId: teamId,
      createdAt: now,
      modifiedAt: now,
      color: color,
    );
  }

  /// دالة `copyWith`:
  /// تنشئ نسخة جديدة من كائن المشروع مع إمكانية تعديل بعض الخصائص.
  /// مفيدة جدًا في إدارة الحالة (State Management) عند الحاجة لتحديث الواجهة بكائن جديد
  /// بدلاً من تعديل الكائن القديم مباشرة (Immutability).
  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? statusId,
    // ... باقي الخصائص
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statusId: statusId ?? this.statusId,
      // ... باقي الخصائص
      // يتم استخدام القيمة الجديدة إذا تم توفيرها، وإلا يتم استخدام القيمة الحالية (this).
      budget: budget ?? this.budget,
      imageUrl: imageUrl ?? this.imageUrl,
      teamId: teamId ?? this.teamId,
      ownerId: ownerId ?? this.ownerId,
      isDeleted: isDeleted ?? this.isDeleted,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSynced: isSynced ?? this.isSynced,
      color: color ?? this.color,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      taskCount: taskCount ?? this.taskCount,
      progress: progress ?? this.progress,
      ownerName: ownerName ?? this.ownerName,
    );
  }
}
