// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // لإضافة تأثيرات حركية.
import 'package:provider/provider.dart'; // للوصول إلى بيانات المستخدم.
import 'package:task_ly/providers/user_provider.dart' show UserProvider;
import '../helpers/database_helper.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart'; // استيراد بطاقة عرض المهمة.
import 'task_details_screen.dart'; // استيراد شاشة تفاصيل المهمة.

// `enum` لتحديد أنواع الفلترة المتاحة للمهام المستقلة.
enum OrphanTaskFilter { all, favorite, archived, completed, deleted }
// `enum` لتحديد أنواع الترتيب المتاحة.
enum OrphanTaskSort { modifiedAt, endDate, name }

/// هذه الواجهة (`StatefulWidget`) مسؤولة عن عرض "المهام الكبيرة" أو "المهام اليتيمة"
/// (Orphan Tasks)، وهي المهام التي لا تنتمي إلى أي مشروع.
class TasksScreen extends StatefulWidget {
  final int updateCounter; // لإجبار الواجهة على إعادة التحميل عند الحاجة.
  const TasksScreen({super.key, required this.updateCounter});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // --- إدارة الحالة (State Management) ---
  List<Task> _allTasks = []; // قائمة بجميع المهام التي تم جلبها من قاعدة البيانات.
  List<Task> _filteredTasks = []; // القائمة التي يتم عرضها بعد تطبيق الفلترة والترتيب.
  bool _isLoading = true; // لتحديد ما إذا كانت البيانات قيد التحميل.

  String _searchQuery = ''; // لتخزين نص البحث الحالي.
  OrphanTaskFilter _currentFilter = OrphanTaskFilter.all; // الفلتر الحالي.
  OrphanTaskSort _currentSort = OrphanTaskSort.modifiedAt; // الترتيب الحالي.

  bool _isSelectionMode = false; // هل نحن في وضع التحديد المتعدد؟
  final Set<String> _selectedTaskIds = {}; // مجموعة لتخزين معرفات المهام المحددة.

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغير `updateCounter`، فهذا يعني أن هناك طلبًا لإعادة تحميل البيانات.
    if (widget.updateCounter != oldWidget.updateCounter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTasks();
      });
    }
  }

  /// دالة `_loadTasks`: مسؤولة عن جلب المهام المستقلة من قاعدة البيانات.
  Future<void> _loadTasks() async {
    // الحصول على معرف المستخدم الحقيقي من `UserProvider`.
    final String? currentUserId = Provider.of<UserProvider>(context, listen: false).user?.id;

    if (currentUserId == null) {
      print("خطأ فادح: لا يمكن تحميل المهام بدون مستخدم مسجل دخوله.");
      if (mounted) setState(() => _isLoading = false);
      return; // إيقاف العملية.
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      // استدعاء دالة قاعدة البيانات لجلب المهام المستقلة.
      _allTasks = await DatabaseHelper.instance.getOrphanTasksForUser(currentUserId);
      _applyFilterAndSort(); // تطبيق الفلترة والترتيب على البيانات الجديدة.
    } catch (e) {
      print("Error loading orphan tasks: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// دالة `_applyFilterAndSort`: تقوم بتصفية وترتيب قائمة المهام.
  void _applyFilterAndSort() {
    List<Task> tempTasks;
    // تطبيق الفلترة.
    switch (_currentFilter) {
      case OrphanTaskFilter.favorite: tempTasks = _allTasks.where((t) => t.isFavorite && !t.isArchived && !t.isDeleted).toList(); break;
      case OrphanTaskFilter.archived: tempTasks = _allTasks.where((t) => t.isArchived && !t.isDeleted).toList(); break;
      case OrphanTaskFilter.completed: tempTasks = _allTasks.where((t) => t.isCompleted && !t.isArchived && !t.isDeleted).toList(); break;
      case OrphanTaskFilter.deleted: tempTasks = _allTasks.where((t) => t.isDeleted).toList(); break;
      case OrphanTaskFilter.all: default: tempTasks = _allTasks.where((t) => !t.isArchived && !t.isDeleted).toList(); break;
    }
    // تطبيق البحث.
    if (_searchQuery.isNotEmpty) {
      tempTasks = tempTasks.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    // تطبيق الترتيب.
    switch (_currentSort) {
      case OrphanTaskSort.name: tempTasks.sort((a, b) => a.name.compareTo(b.name)); break;
      case OrphanTaskSort.endDate: tempTasks.sort((a, b) { if (a.endDate == null) return 1; if (b.endDate == null) return -1; return a.endDate!.compareTo(b.endDate!); }); break;
      case OrphanTaskSort.modifiedAt: default: tempTasks.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt)); break;
    }
    if (mounted) setState(() => _filteredTasks = tempTasks);
  }

  /// دالة لتحديث حالة مهمة واحدة في القائمة المحلية (تُستدعى من `TaskCard`).
  void _updateLocalTaskState(Task updatedTask) {
    final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      setState(() {
        _allTasks[index] = updatedTask;
        _applyFilterAndSort();
      });
    }
  }

  /// دالة للتبديل بين تحديد وإلغاء تحديد مهمة.
  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
        _isSelectionMode = true;
      }
    });
  }

  /// دالة لمسح جميع التحديدات.
  void _clearSelection() {
    setState(() {
      _selectedTaskIds.clear();
      _isSelectionMode = false;
    });
  }

  /// دالة لتنفيذ إجراء جماعي على المهام المحددة.
  Future<void> _performBulkAction(Function(Task t) action) async {
    final tasksToUpdate = _allTasks.where((t) => _selectedTaskIds.contains(t.id)).toList();
    for (var task in tasksToUpdate) {
      action(task);
      task.modifiedAt = DateTime.now();
      await DatabaseHelper.instance.updateTask(task);
    }
    setState(() {
      _applyFilterAndSort();
      _clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTasks.isEmpty
              ? _buildEmptyState()
              : _buildTasksList(),
    );
  }

  /// بناء الشريط العلوي العادي (مع البحث والفلترة).
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('المهام الكبيرة'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) => setState(() { _searchQuery = value; _applyFilterAndSort(); }),
            decoration: InputDecoration(
              hintText: 'ابحث عن مهمة...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<OrphanTaskSort>(/* ... قائمة الترتيب ... */),
        PopupMenuButton<OrphanTaskFilter>(/* ... قائمة الفلترة ... */),
      ],
    );
  }

  /// بناء الشريط العلوي في وضع التحديد.
  AppBar _buildSelectionAppBar() {
    bool isArchivedView = _currentFilter == OrphanTaskFilter.archived;
    return AppBar(
      title: Text('${_selectedTaskIds.length} تم تحديده'),
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
      actions: [
        IconButton(tooltip: 'تفضيل', icon: const Icon(Icons.favorite_border), onPressed: () => _performBulkAction((t) => t.isFavorite = !t.isFavorite)),
        IconButton(tooltip: isArchivedView ? 'إلغاء الأرشفة' : 'أرشفة', icon: Icon(isArchivedView ? Icons.unarchive_outlined : Icons.archive_outlined), onPressed: () => _performBulkAction((t) => t.isArchived = !isArchivedView)),
        IconButton(tooltip: 'حذف (نقل للسلة)', icon: const Icon(Icons.delete_outline), onPressed: () => _performBulkAction((t) => t.isDeleted = true)),
      ],
    );
  }

  /// بناء قائمة المهام.
  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);
        return FadeInUp(
          child: GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(task.id);
              } else {
                // الانتقال إلى شاشة تفاصيل المهمة عند الضغط.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
                );
              }
            },
            onLongPress: () => _toggleSelection(task.id),
            child: TaskCard(
              task: task,
              isSelected: isSelected,
              onStateChanged: _updateLocalTaskState,
            ),
          ),
        );
      },
    );
  }

  /// بناء الواجهة التي تظهر عند عدم وجود مهام.
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('لا توجد مهام مستقلة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}
