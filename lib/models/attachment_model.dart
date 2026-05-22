// lib/models/attachment_model.dart

// استيراد مكتبة لإنشاء معرفات (IDs) فريدة.
import 'package:uuid/uuid.dart';

/// هذا الكلاس (Model) يمثل ملفًا مرفقًا واحدًا (مثل صورة، فيديو، PDF).
/// يمكن ربط المرفقات بالمشاريع أو المهام.
class Attachment {
  // --- خصائص الكلاس ---

  final String id; // المعرف الفريد للمرفق.
  final String fileName; // اسم الملف الأصلي كما يظهر للمستخدم.
  final String filePath; // مسار تخزين الملف داخل الجهاز.
  final String? fileType; // نوع الملف (امتداده)، مثل 'jpg', 'pdf', 'mp4'.
  final int? fileSize; // حجم الملف بالبايت.
  final String? projectId; // معرف المشروع الذي يرتبط به المرفق (إذا وجد).
  final String? taskId; // معرف المهمة التي يرتبط بها المرفق (إذا وجدت).
  final String uploadedByUserId; // معرف المستخدم الذي قام برفع الملف.
  final DateTime createdAt; // تاريخ ووقت رفع الملف.
  final bool isSynced; // هل تمت مزامنة هذا المرفق مع الخادم السحابي أم لا.
  
  /// `thumbnailPath`: مسار الصورة المصغرة للملف (خاص بالفيديوهات).
  /// تُستخدم لعرض صورة معاينة سريعة للفيديو دون الحاجة لتحميله بالكامل.
  final String? thumbnailPath;

  // --- المُنشئ (Constructor) ---

  /// المُنشئ الأساسي لإنشاء كائن `Attachment`.
  Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileType,
    this.fileSize,
    this.projectId,
    this.taskId,
    required this.uploadedByUserId,
    required this.createdAt,
    this.isSynced = false,
    this.thumbnailPath, // تمت إضافة مسار الصورة المصغرة هنا.
  });

  // --- دوال التحويل ---

  /// دالة مصنعية `fromMap`:
  /// تقوم بإنشاء كائن `Attachment` من خريطة (Map) قادمة من قاعدة البيانات.
  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'],
      fileName: map['fileName'],
      filePath: map['filePath'],
      fileType: map['fileType'],
      fileSize: map['fileSize'],
      projectId: map['projectId'],
      taskId: map['taskId'],
      uploadedByUserId: map['uploadedByUserId'],
      createdAt: DateTime.parse(map['createdAt']), // تحويل النص إلى تاريخ.
      isSynced: map['isSynced'] == 1, // تحويل 1/0 إلى true/false.
      thumbnailPath: map['thumbnailPath'], // قراءة مسار الصورة المصغرة.
    );
  }

  /// دالة `toMap`:
  /// تقوم بتحويل كائن `Attachment` إلى خريطة (Map) لحفظه في قاعدة البيانات.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'projectId': projectId,
      'taskId': taskId,
      'uploadedByUserId': uploadedByUserId,
      'createdAt': createdAt.toIso8601String(), // تحويل التاريخ إلى نص.
      'isSynced': isSynced ? 1 : 0, // تحويل true/false إلى 1/0.
      'thumbnailPath': thumbnailPath, // إضافة مسار الصورة المصغرة للحفظ.
    };
  }

  /// دالة مصنعية `createNew`:
  /// طريقة سهلة لإنشاء مرفق جديد بمعرف فريد ووقت إنشاء حالي.
  /// مفيدة عند إضافة مرفق جديد من قبل المستخدم.
  factory Attachment.createNew({
    required String fileName,
    required String filePath,
    required String uploadedByUserId,
    String? fileType,
    int? fileSize,
    String? projectId,
    String? taskId,
    String? thumbnailPath, // معامل جديد لاستقبال مسار الصورة المصغرة.
  }) {
    return Attachment(
      id: const Uuid().v4(), // إنشاء ID فريد تلقائيًا.
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      projectId: projectId,
      taskId: taskId,
      uploadedByUserId: uploadedByUserId,
      createdAt: DateTime.now(), // استخدام الوقت الحالي تلقائيًا.
      thumbnailPath: thumbnailPath, // تمرير مسار الصورة المصغرة.
    );
  }
}
