// lib/helpers/database_helper.dart

import 'dart:async';
import 'dart:io'; // للتعامل مع الملفات والمجلدات.
import 'package:path/path.dart'; // لتجميع مسارات الملفات بشكل صحيح على مختلف الأنظمة.
import 'package:path/path.dart' as p; // استخدام اسم مستعار لتجنب التعارض.
import 'package:path_provider/path_provider.dart'; // للحصول على مسارات المجلدات القياسية في الجهاز.
import 'package:sqflite/sqflite.dart'; // المكتبة الأساسية للتعامل مع قواعد بيانات SQLite.
import 'package:task_ly/models/daily_task_model.dart'; // استيراد نموذج المهام اليومية.
import 'package:task_ly/models/expense_model.dart'; // استيراد نموذج المصروفات.
import 'package:uuid/uuid.dart'; // لإنشاء معرفات فريدة.
import 'package:video_thumbnail/video_thumbnail.dart'; // لإنشاء صور مصغرة من الفيديوهات.

// استيراد نماذج البيانات (Models) التي سيتم تخزينها في قاعدة البيانات.
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/attachment_model.dart';
import '../models/message_model.dart';

/// هذا الكلاس هو المسؤول الوحيد عن كل ما يتعلق بقاعدة البيانات المحلية (SQLite).
/// يتضمن إنشاء الجداول، وإضافة البيانات، وقراءتها، وتحديثها، وحذفها.
class DatabaseHelper {
  // --- 1. إعدادات قاعدة البيانات ---
  static const _databaseName = "TasklyApp.db"; // اسم ملف قاعدة البيانات.
  static const _databaseVersion = 30; // رقم الإصدار، يتم زيادته عند إجراء تغييرات على هيكل الجداول.

  // --- 2. أسماء الجداول ---
  // تعريف أسماء الجداول كثوابت لتجنب الأخطاء الإملائية.
  static const tableUsers = 'users';
  static const tableProjects = 'projects';
  static const tableTasks = 'tasks';
  static const tableDailyTasks = 'daily_tasks';
  static const tableTeams = 'teams';
  static const tableTeamMembers = 'team_members';
  static const tableUserRelationships = 'user_relationships';
  static const tableRelationshipStatuses = 'relationship_statuses';
  static const tableStatuses = 'statuses';
  static const tableMessages = 'messages';
  static const tableNotifications = 'notifications';
  static const tableAppSettings = 'app_settings';
  static const tableExpenses = 'expenses';
  static const tableAttachments = 'attachments';
  static const tableExpenseCategories = 'expense_categories';
  static const tableAiMessages = 'ai_messages'; // جدول رسائل الدردشة الذكية.

  // --- 3. نمط Singleton ---
  // هذا النمط يضمن وجود نسخة (instance) واحدة فقط من `DatabaseHelper` في التطبيق بأكمله.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // دالة `get` للوصول إلى قاعدة البيانات.
  // إذا كانت قاعدة البيانات مفتوحة بالفعل، يتم إرجاعها مباشرة.
  // إذا لم تكن، يتم تهيئتها أولاً ثم إرجاعها.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- 4. تهيئة وإنشاء قاعدة البيانات ---
  Future<Database> _initDatabase() async {
    // تحديد مسار حفظ ملف قاعدة البيانات في الجهاز.
    String path = join(await getDatabasesPath(), _databaseName);
    // فتح (أو إنشاء) قاعدة البيانات.
    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'), // تفعيل خاصية المفاتيح الأجنبية.
      onCreate: _onCreate, // دالة تُستدعى عند إنشاء قاعدة البيانات لأول مرة.
      onDowngrade: onDatabaseDowngradeDelete, // دالة للتعامل مع تخفيض الإصدار (عادة بحذف وإعادة الإنشاء).
      onUpgrade: _onUpgrade, // دالة تُستدعى عند زيادة رقم الإصدار.
    );
  }

  /// دالة `_onUpgrade`: تُنفذ عندما يكون رقم الإصدار الجديد أعلى من القديم.
  /// تستخدم لتعديل هيكل قاعدة البيانات دون حذف بيانات المستخدم (مثل إضافة عمود جديد لجدول).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('ترقية قاعدة البيانات من الإصدار $oldVersion إلى $newVersion');

    // كل كتلة `if` تتحقق من الإصدار القديم وتطبق التغييرات اللازمة للوصول إلى الإصدارات الأحدث.
    // الأكواد داخل هذه الكتل معطلة حاليًا (commented out) ولكنها توضح كيفية إجراء الترقية.
    if (oldVersion < 29) {
      print("تطبيق التغييرات للإصدار 29: إنشاء جدول ai_messages...");
      await db.execute('''
        CREATE TABLE $tableAiMessages (
          id TEXT PRIMARY KEY,
          conversationId TEXT NOT NULL,
          content TEXT NOT NULL,
          isFromUser INTEGER NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 30) {
      print("تطبيق التغييرات للإصدار 30: إنشاء جدول daily_tasks...");
      await db.execute('''
        CREATE TABLE $tableDailyTasks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          startTime TEXT,
          endTime TEXT,
          budget REAL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          isFavorite INTEGER NOT NULL DEFAULT 0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          modifiedAt TEXT NOT NULL,
          ownerId TEXT NOT NULL,
          FOREIGN KEY (ownerId) REFERENCES $tableUsers (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// دالة `_onCreate`: تُنفذ مرة واحدة فقط عند إنشاء ملف قاعدة البيانات.
  /// وظيفتها هي إنشاء جميع الجداول وإضافة البيانات الأولية (seeding).
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db); // إنشاء هيكل الجداول.
    await _seedDatabase(db); // ملء الجداول ببيانات افتراضية.
  }

  /// دالة `_createTables`: تحتوي على أوامر `CREATE TABLE` لجميع جداول التطبيق.
  Future<void> _createTables(Database db) async {
    final batch = db.batch(); // استخدام `batch` لتنفيذ عدة أوامر دفعة واحدة لتحسين الأداء.

    // أوامر إنشاء الجداول المختلفة للتطبيق.
    batch.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY, name TEXT, email TEXT UNIQUE ,
        phoneNumber TEXT UNIQUE, avatarUrl TEXT, createdAt TEXT NOT NULL, lastLogin TEXT
      )
    ''');
    
    batch.execute('''
      CREATE TABLE $tableProjects (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, imageUrl TEXT,
        statusId INTEGER NOT NULL, ownerId TEXT, teamId TEXT,
        startDate TEXT NOT NULL, endDate TEXT NOT NULL, budget REAL,
        isFavorite INTEGER NOT NULL DEFAULT 0, isArchived INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL,
        modifiedAt TEXT NOT NULL, isSynced INTEGER NOT NULL DEFAULT 0,
        color TEXT, totalExpenses REAL NOT NULL DEFAULT 0.0
      )
    ''');
    
    batch.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT,
        statusId INTEGER NOT NULL, projectId TEXT, parentTaskId TEXT,
        ownerId TEXT, assigneeId TEXT, startDate TEXT, endDate TEXT, budget REAL,
        isFavorite INTEGER NOT NULL DEFAULT 0, isArchived INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0, progress REAL NOT NULL DEFAULT 0.0,
        priority INTEGER NOT NULL DEFAULT 1, isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL, modifiedAt TEXT NOT NULL, isSynced INTEGER NOT NULL DEFAULT 0,
        totalExpenses REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // ... (باقي أوامر إنشاء الجداول مثل الفرق، الأعضاء، المرفقات، إلخ) ...

    // إنشاء جدول رسائل الذكاء الاصطناعي.
    batch.execute('''
      CREATE TABLE $tableAiMessages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        content TEXT NOT NULL,
        isFromUser INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // إنشاء جدول المهام اليومية.
    batch.execute('''
      CREATE TABLE $tableDailyTasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        startTime TEXT,
        endTime TEXT,
        budget REAL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        modifiedAt TEXT NOT NULL,
        ownerId TEXT NOT NULL,
        FOREIGN KEY (ownerId) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    await batch.commit(); // تنفيذ جميع الأوامر في الـ batch.
    print("[DB Helper] تم إنشاء جميع الجداول بنجاح.");
  }
  
  /// دالة `_seedDatabase`: تقوم بإضافة بيانات أولية (افتراضية) عند إنشاء قاعدة البيانات لأول مرة.
  /// مفيدة لتهيئة التطبيق ببيانات جاهزة للاستخدام (مثل حالات المهام، مستخدم افتراضي، إلخ).
  Future<void> _seedDatabase(Database db) async {
    print("--- بدء إضافة البيانات الأولية (Seeding) ---");
    try {
      // ... (كود إضافة المستخدمين، المشاريع، المهام، والبيانات الافتراضية الأخرى) ...
      // هذا الجزء يحتوي على بيانات تجريبية لتعبئة التطبيق عند أول تشغيل.
    } catch (e) {
      print("--- خطأ فادح أثناء إضافة البيانات الأولية: $e ---");
      rethrow;
    }
  }

  // --- دوال العمليات الأساسية (CRUD: Create, Read, Update, Delete) ---

  /// `insert`: إضافة صف جديد إلى جدول معين.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await instance.database;
    return await db.insert(table, data);
  }

  /// `queryAllRows`: قراءة جميع الصفوف من جدول معين.
  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  /// `update`: تحديث صف موجود في جدول.
  Future<int> update(String table, Map<String, dynamic> data) async {
    Database db = await instance.database;
    String id = data['id'];
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  /// `delete`: حذف صف من جدول باستخدام الـ ID.
  Future<int> delete(String table, String id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // --- دوال مخصصة لجلب البيانات ---

  /// جلب المشاريع مع إحصائياتها (عدد المهام ومتوسط التقدم).
  Future<List<Map<String, dynamic>>> getProjectsWithStats(String userId) async {
    final db = await instance.database;
    // استعلام معقد يجمع بيانات من عدة جداول.
    final result = await db.rawQuery('''
      SELECT DISTINCT
        P.*,
        U_owner.name as ownerName,
        (SELECT COUNT(*) FROM $tableTasks WHERE projectId = P.id) as taskCount,
        (SELECT AVG(progress) FROM $tableTasks WHERE projectId = P.id) as avgProgress
      FROM $tableProjects P
      LEFT JOIN $tableUsers U_owner ON P.ownerId = U_owner.id
      LEFT JOIN $tableTeams T ON P.teamId = T.id
      LEFT JOIN $tableTeamMembers TM ON T.id = TM.teamId
      WHERE P.ownerId = ? OR TM.userId = ?
      GROUP BY P.id
      ORDER BY P.modifiedAt DESC
    ''', [userId, userId]);
    return result;
  }

  /// تحديث بيانات مشروع معين.
  Future<int> updateProject(Project project) async {
    final db = await instance.database;
    return await db.update(
      tableProjects,
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }
  
  /// جلب المهام الخاصة بمشروع معين.
  Future<List<Map<String, dynamic>>> getTasksForProject(String projectId) async {
    Database db = await instance.database;
    return await db.query(
      tableTasks,
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt ASC',
    );
  }

  /// إضافة مشروع مع مرفقاته في عملية واحدة (Transaction).
  Future<void> insertProjectWithAttachments(Project project, List<File> attachments, String uploaderId) async {
    final db = await instance.database;
    // ... (كود نسخ الملفات وإنشاء الصور المصغرة للفيديو) ...
    await db.transaction((txn) async {
      await txn.insert(tableProjects, project.toMap());
      // ... (حلقة لإضافة كل مرفق وربطه بالمشروع) ...
    });
  }

  // --- دوال المهام اليومية (Daily Tasks) ---

  /// جلب جميع المهام اليومية لمستخدم معين في تاريخ محدد.
  Future<List<DailyTask>> getDailyTasksForUser(String userId, DateTime date) async {
    final db = await instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      tableDailyTasks,
      where: 'ownerId = ? AND startTime >= ? AND startTime <= ?',
      whereArgs: [userId, startOfDay, endOfDay],
      orderBy: 'startTime ASC',
    );
    if (maps.isEmpty) return [];
    return maps.map((map) => DailyTask.fromMap(map)).toList();
  }

  /// إضافة أو تحديث مهمة يومية.
  Future<void> saveDailyTask(DailyTask task) async {
    final db = await instance.database;
    await db.insert(
      tableDailyTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // إذا كانت المهمة موجودة، يتم استبدالها.
    );
  }

  /// حذف مهمة يومية.
  Future<void> deleteDailyTask(String taskId) async {
    final db = await instance.database;
    await db.delete(tableDailyTasks, where: 'id = ?', whereArgs: [taskId]);
  }

  // --- دوال الدردشة الذكية (AI Chat) ---

  /// جلب جميع رسائل محادثة معينة مع الذكاء الاصطناعي.
  Future<List<Map<String, dynamic>>> getAiMessages(String conversationId) async {
    final db = await database;
    return await db.query(
      tableAiMessages,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt ASC', // ترتيب الرسائل حسب وقت الإنشاء.
    );
  }

  /// إضافة رسالة جديدة في محادثة الذكاء الاصطناعي.
  Future<void> insertAiMessage(Map<String, dynamic> messageData) async {
    final db = await database;
    await db.insert(
      tableAiMessages,
      messageData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// حذف رسالة معينة من محادثة الذكاء الاصطناعي.
  Future<void> deleteAiMessage(String messageId) async {
    final db = await database;
    await db.delete(tableAiMessages, where: 'id = ?', whereArgs: [messageId]);
  }

  /// حذف محادثة كاملة مع الذكاء الاصطناعي.
  Future<void> deleteAiConversation(String conversationId) async {
    final db = await database;
    await db.delete(tableAiMessages, where: 'conversationId = ?', whereArgs: [conversationId]);
  }
}
