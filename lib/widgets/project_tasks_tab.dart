// lib/widgets/project_tasks_tab.dart

// --- 1. استيراد الحزم الأساسية ---
import 'package:flutter/material.dart'; // حزمة Flutter الرئيسية للواجهات.
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية عند ظهور العناصر.

// --- 2. استيراد ملفات المشروع ---
import '../helpers/database_helper.dart'; // للوصول إلى دوال قاعدة البيانات.
import '../models/task_model.dart'; // لاستخدام نموذج البيانات `Task`.
import '../screens/task_details_screen.dart'; // للانتقال إلى شاشة تفاصيل المهمة.
import '../widgets/task_card.dart'; // لاستخدام بطاقة عرض المهمة.

// =========================================================================
// Enums للتحكم في الفلترة والترتيب
// =========================================================================
/// `enum` لتحديد أنواع الفلترة المتاحة للمهام.
enum TaskFilter { all, favorite, archived, completed, deleted }
/// `enum` لتحديد أنواع الترتيب المتاحة للمهام.
enum TaskSort { createdAt, endDate, name }

// =========================================================================
// الفئة الرئيسية: ProjectTasksTab
// =========================================================================
/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض تبويب "المهام".
/// تم تصميمها لتكون مرنة، حيث يمكنها عرض المهام المرتبطة بمشروع (`projectId`)
/// أو المهام الفرعية لمهمة رئيسية (`taskId`).
///
/// تحتوي على منطق للبحث، الفلترة، الترتيب، والتحديد المتعدد للمهام.
class ProjectTasksTab extends StatefulWidget {
  // --- الخصائص (Properties) ---
  final String? projectId; // معرف المشروع.
  final String? taskId; // معرف المهمة الرئيسية.

  // --- المُنشئ (Constructor) ---
  const ProjectTasksTab({super.key, this.projectId, this.taskId})
      // `assert` يضمن أن أحد المعرفين قد تم تمريره، وإلا سيطلق خطأ أثناء التطوير.
      : assert(projectId != null || taskId != null, 'Either projectId or taskId must be provided');

  @override
  State<ProjectTasksTab> createState() => _ProjectTasksTabState();
}

// =========================================================================
// حالة الفئة الرئيسية: _ProjectTasksTabState
// =========================================================================
class _ProjectTasksTabState extends State<ProjectTasksTab> {
  // --- متغيرات الحالة (State Variables) ---
  List<Task> _allTasks = []; // قائمة تحتوي على جميع المهام التي تم جلبها من قاعدة البيانات.
  List<Task> _filteredTasks = []; // قائمة تحتوي على المهام بعد تطبيق البحث والفلترة والترتيب.
  bool _isLoading = true; // لتحديد ما إذا كانت البيانات قيد التحميل.

  String _searchQuery = ''; // لتخزين نص البحث الحالي.
  TaskFilter _currentFilter = TaskFilter.all; // الفلتر الحالي المطبق.
  TaskSort _currentSort = TaskSort.createdAt; // الترتيب الحالي المطبق.

  bool _isSelectionMode = false; // هل وضع التحديد المتعدد مفعل؟
  final Set<String> _selectedTaskIds = {}; // مجموعة لتخزين معرفات المهام المحددة.

  // --- دورة حياة الواجهة (Lifecycle Methods) ---
  @override
  void initState() {
    super.initState();
    // عند بناء الواجهة لأول مرة، نبدأ عملية جلب المهام.
    _loadTasks();
  }

  // --- الدوال المنطقية (Logic Functions) ---

  /// دالة `_loadTasks`: مسؤولة عن جلب قائمة المهام من قاعدة البيانات.
  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> tasksData;
      // منطق ذكي: استدعاء الدالة المناسبة من `DatabaseHelper` بناءً على المعرف الممرر.
      if (widget.projectId != null) {
        tasksData = await DatabaseHelper.instance.getTasksForProject(widget.projectId!);
      } else {
        tasksData = await DatabaseHelper.instance.getTasksForTask(widget.taskId!);
      }
      
      if (mounted) {
        _allTasks = tasksData.map((map) => Task.fromMap(map)).toList();
        _applyFilterAndSort(); // تطبيق الفلترة والترتيب الافتراضي بعد جلب البيانات.
      }
    } catch (e) {
      print("Error loading tasks: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// دالة `_applyFilterAndSort`: تقوم بتصفية وترتيب قائمة المهام بناءً على الاختيارات الحالية.
  void _applyFilterAndSort() {
    List<Task> tempTasks;
    // 1. تطبيق الفلترة.
    switch (_currentFilter) {
      // ... (منطق الفلترة بناءً على `_currentFilter`) ...
      default:
        tempTasks = _allTasks.where((t) => !t.isArchived && !t.isDeleted).toList();
        break;
    }

    // 2. تطبيق البحث.
    if (_searchQuery.isNotEmpty) {
      tempTasks = tempTasks.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 3. تطبيق الترتيب.
    switch (_currentSort) {
      // ... (منطق الترتيب بناءً على `_currentSort`) ...
      default:
        tempTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    if (mounted) setState(() => _filteredTasks = tempTasks);
  }

  /// دالة `_updateLocalTaskState`: تُستخدم لتحديث حالة مهمة واحدة في القائمة المحلية.
  /// تُستدعى هذه الدالة من `TaskCard` عند تغيير حالة (مثل المفضلة أو الإنجاز).
  void _updateLocalTaskState(Task updatedTask) {
    final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      setState(() {
        _allTasks[index] = updatedTask;
        _applyFilterAndSort();
      });
    }
  }

  /// دوال لإدارة وضع التحديد المتعدد.
  void _toggleSelection(String taskId) { /* ... */ }
  void _clearSelection() { /* ... */ }

  /// دالة `_performBulkAction`: لتنفيذ إجراء جماعي على المهام المحددة.
  Future<void> _performBulkAction(Function(Task t) action) async {
    final tasksToUpdate = _allTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
    for (var task in tasksToUpdate) {
      action(task); // تطبيق الإجراء (مثل `t.isArchived = true`).
      task.modifiedAt = DateTime.now();
      await DatabaseHelper.instance.updateTask(task);
    }
    setState(() {
      _applyFilterAndSort();
      _clearSelection();
    });
  }

  // --- بناء الواجهة (UI Build Method) ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // عرض شريط أدوات التحديد أو شريط البحث والفلترة.
        _isSelectionMode ? _buildSelectionAppBar() : _buildSearchAndFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTasks.isEmpty
                  ? const Center(child: Text('لا توجد مهام هنا.'))
                  : _buildTasksList(),
        ),
      ],
    );
  }

  /// ويدجت `_buildSelectionAppBar`: لبناء شريط الأدوات الذي يظهر في وضع التحديد المتعدد.
  Widget _buildSelectionAppBar() {
    bool isArchivedView = _currentFilter == TaskFilter.archived;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
          Text('${_selectedTaskIds.length} تم تحديده', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(tooltip: 'تفضيل', icon: const Icon(Icons.favorite_border), onPressed: () => _performBulkAction((t) => t.isFavorite = !t.isFavorite)),
          IconButton(tooltip: isArchivedView ? 'إلغاء الأرشفة' : 'أرشفة', icon: Icon(isArchivedView ? Icons.unarchive_outlined : Icons.archive_outlined), onPressed: () => _performBulkAction((t) => t.isArchived = !isArchivedView)),
          IconButton(tooltip: 'حذف (نقل للسلة)', icon: const Icon(Icons.delete_outline), onPressed: () => _performBulkAction((t) => t.isDeleted = true)),
        ],
      ),
    );
  }

  /// ويدجت `_buildSearchAndFilterBar`: لبناء شريط البحث والفلترة والترتيب.
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() { _searchQuery = value; _applyFilterAndSort(); }),
              decoration: InputDecoration(hintText: 'ابحث في المهام...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), filled: true, fillColor: Theme.of(context).colorScheme.surface, contentPadding: EdgeInsets.zero),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<TaskSort>(onSelected: (sort) => setState(() { _currentSort = sort; _applyFilterAndSort(); }), icon: const Icon(Icons.sort_rounded), itemBuilder: (context) => [ /* ... */ ]),
          PopupMenuButton<TaskFilter>(onSelected: (filter) => setState(() { _currentFilter = filter; _applyFilterAndSort(); }), icon: const Icon(Icons.filter_list_rounded), itemBuilder: (context) => [ /* ... */ ]),
        ],
      ),
    );
  }

  /// ويدجت `_buildTasksList`: لبناء قائمة المهام.
  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);
        return FadeInUp(
          from: 20,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 40),
          child: GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(task.id);
              } else {
                // الانتقال إلى شاشة تفاصيل المهمة عند الضغط.
                Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)));
              }
            },
            onLongPress: () => _toggleSelection(task.id), // تفعيل وضع التحديد عند الضغط المطول.
            child: TaskCard(
              task: task,
              isSelected: isSelected,
              onStateChanged: _updateLocalTaskState, // تمرير دالة التحديث للبطاقة.
            ),
          ),
        );
      },
    );
  }
}
